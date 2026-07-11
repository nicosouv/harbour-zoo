// Engine unit tests, runnable on plain desktop Qt5 (no device/SDK). Covers the two foundations:
// deterministic RNG and the append-only EventStore round-trip + install-salt persistence.
#include <QtTest>
#include <QSet>
#include <QJsonObject>
#include <QJsonDocument>

#include "engine/Rng.h"
#include "engine/EventStore.h"
#include "engine/Clock.h"
#include "engine/StateProjection.h"

using namespace zoo;

static Event mkEvent(const QString& type, const QString& date, int hour, const QString& payload)
{
    Event e; e.type = type; e.tsUtc = date + "T00:00:00Z";
    e.localDate = date; e.localHour = hour; e.payload = payload;
    return e;
}

class ZooEngineTest : public QObject
{
    Q_OBJECT

private slots:
    // ---- Rng ------------------------------------------------------------------------------
    void rng_isDeterministic()
    {
        Rng a(12345), b(12345);
        for (int i = 0; i < 100; ++i)
            QCOMPARE(a.next(), b.next());

        // Different seeds must diverge (astronomically unlikely to collide on the first value).
        Rng c(12345), d(54321);
        QVERIFY(c.next() != d.next());
    }

    void rng_doubleInUnitInterval()
    {
        Rng r(777);
        for (int i = 0; i < 10000; ++i) {
            const double x = r.nextDouble();
            QVERIFY(x >= 0.0);
            QVERIFY(x < 1.0);
        }
    }

    void rng_boundedIsInRangeAndSpreads()
    {
        Rng r(42);
        QSet<quint32> seen;
        for (int i = 0; i < 5000; ++i) {
            const quint32 v = r.nextBounded(10);
            QVERIFY(v < 10u);
            seen.insert(v);
        }
        QCOMPARE(seen.size(), 10);          // covers the whole range
        QCOMPARE(Rng(1).nextBounded(0), 0u); // bound 0 is safe
    }

    void rng_mixIsPureAndSensitive()
    {
        QCOMPARE(Rng::mix(1, 2), Rng::mix(1, 2));   // pure
        QVERIFY(Rng::mix(1, 2) != Rng::mix(2, 1));  // order matters
        QVERIFY(Rng::mix(100, 0) != Rng::mix(100, 1));
    }

    // ---- EventStore -----------------------------------------------------------------------
    void eventstore_roundTrip()
    {
        EventStore store(QStringLiteral("test_roundtrip"));
        QVERIFY(store.open(QStringLiteral(":memory:")));
        QVERIFY(store.bootstrap(0xABCDEF));

        QVERIFY(store.appendEvent("app_opened", "2026-07-11T09:00:00Z", "2026-07-11", 9, "{}") > 0);
        QVERIFY(store.appendEvent("challenge_completed", "2026-07-11T09:01:00Z", "2026-07-11", 9,
                                  "{\"challenge_id\":\"triangles\"}") > 0);
        QVERIFY(store.appendEvent("currency_earned", "2026-07-11T09:01:00Z", "2026-07-11", 9,
                                  "{\"currency\":\"crumbs\",\"amount\":10}") > 0);

        QCOMPARE(store.eventCount(), 3);

        const QVector<Event> evs = store.events();
        QCOMPARE(evs.size(), 3);
        // Ordered by seq (append order), monotonic and gapless from 1.
        QCOMPARE(evs[0].seq, qint64(1));
        QCOMPARE(evs[1].seq, qint64(2));
        QCOMPARE(evs[2].seq, qint64(3));
        QCOMPARE(evs[0].type, QStringLiteral("app_opened"));
        QCOMPARE(evs[1].type, QStringLiteral("challenge_completed"));
        QCOMPARE(evs[1].localDate, QStringLiteral("2026-07-11"));
        QCOMPARE(evs[1].localHour, 9);
        QVERIFY(evs[2].payload.contains(QStringLiteral("crumbs")));
    }

    void eventstore_installSaltPersistsAndIsStable()
    {
        EventStore store(QStringLiteral("test_salt"));
        QVERIFY(store.open(QStringLiteral(":memory:")));

        QVERIFY(store.bootstrap(Q_UINT64_C(0x0123456789ABCDEF)));
        QCOMPARE(store.installSalt(), Q_UINT64_C(0x0123456789ABCDEF));

        // A second bootstrap must NOT overwrite an existing salt (install identity is permanent).
        QVERIFY(store.bootstrap(Q_UINT64_C(0xFFFFFFFFFFFFFFFF)));
        QCOMPARE(store.installSalt(), Q_UINT64_C(0x0123456789ABCDEF));
    }

    // ---- Clock ----------------------------------------------------------------------------
    void clock_fixedDerivations()
    {
        FixedClock clk(QDateTime(QDate(2026, 7, 11), QTime(2, 30), Qt::UTC));
        QCOMPARE(clk.isoUtc(), QStringLiteral("2026-07-11T02:30:00Z"));
        clk.advanceSecs(3600);
        QCOMPARE(clk.nowUtc().time().hour(), 3);
    }

    // ---- StateProjection (the pure reducer) -----------------------------------------------
    void reducer_economyAndHabits()
    {
        ZooState s;
        applyEvent(s, mkEvent("currency_earned", "2026-07-11", 9, "{\"amount\":20}"));
        QCOMPARE(s.crumbs, 20);
        applyEvent(s, mkEvent("currency_spent", "2026-07-11", 9, "{\"amount\":5}"));
        QCOMPARE(s.crumbs, 15);
        applyEvent(s, mkEvent("habit_created", "2026-07-11", 9, "{\"id\":\"h1\",\"name\":\"Water\",\"target\":6}"));
        QCOMPARE(s.habits.size(), 1);
        QCOMPARE(s.habits[0].target, 6);
        applyEvent(s, mkEvent("habit_logged", "2026-07-11", 9, "{\"habit_id\":\"h1\",\"date\":\"2026-07-11\"}"));
        applyEvent(s, mkEvent("habit_logged", "2026-07-11", 9, "{\"habit_id\":\"h1\",\"date\":\"2026-07-11\"}"));
        QCOMPARE(s.habitCount.value("2026-07-11/h1"), 2);
        QCOMPARE(s.habitLogTotal, 2);
        QCOMPARE(s.deeds, 2);
        QCOMPARE(s.streak, 1);
    }

    void reducer_streakAcrossDays()
    {
        ZooState s;
        applyEvent(s, mkEvent("challenge_completed", "2026-07-10", 9, "{}"));
        QCOMPARE(s.streak, 1);
        applyEvent(s, mkEvent("challenge_completed", "2026-07-11", 9, "{}"));
        QCOMPARE(s.streak, 2);   // consecutive day extends
        applyEvent(s, mkEvent("challenge_completed", "2026-07-14", 9, "{}"));
        QCOMPARE(s.streak, 1);   // a gap resets
    }

    void reducer_nightOwlAndMythic()
    {
        ZooState s;
        applyEvent(s, mkEvent("challenge_completed", "2026-07-11", 3, "{}"));
        QVERIFY(s.nightOwl);
        applyEvent(s, mkEvent("egg_hatched", "2026-07-11", 9, "{\"id\":\"b1\",\"seed\":42,\"rarity\":\"mythic\"}"));
        QVERIFY(s.mythicSeen);
        QCOMPARE(s.blobs.size(), 1);
    }

    void reducer_eggClaimedOnce()
    {
        ZooState s;
        applyEvent(s, mkEvent("egg_claimed", "2026-07-11", 9, "{\"id\":\"funfact\",\"crumbs\":200}"));
        applyEvent(s, mkEvent("egg_claimed", "2026-07-11", 9, "{\"id\":\"funfact\",\"crumbs\":200}"));
        QCOMPARE(s.crumbs, 200);   // second claim ignored
    }

    void reducer_jsonRoundTrip()
    {
        ZooState s;
        s.crumbs = 99; s.deeds = 5; s.streak = 3; s.mythicSeen = true;
        Habit h; h.id = "h"; h.name = "Test \"quote\""; h.target = 2; s.habits.append(h);
        s.decorations.insert("rock");
        const ZooState s2 = fromJson(toJson(s));
        QCOMPARE(s2.crumbs, 99);
        QCOMPARE(s2.habits.size(), 1);
        QCOMPARE(s2.habits[0].name, QStringLiteral("Test \"quote\""));
        QCOMPARE(s2.streak, 3);
        QVERIFY(s2.decorations.contains("rock"));
    }

    void reducer_migratedReplacesState()
    {
        ZooState s; s.crumbs = 5;
        QJsonObject snap; snap.insert("crumbs", 500);
        applyEvent(s, mkEvent("migrated", "2026-07-11", 9,
                              QString::fromUtf8(QJsonDocument(snap).toJson(QJsonDocument::Compact))));
        QCOMPARE(s.crumbs, 500);   // the snapshot replaces the whole state
    }

    void reducer_badHabitSlip()
    {
        ZooState s;
        applyEvent(s, mkEvent("habit_created", "2026-07-11", 9, "{\"id\":\"b1\",\"name\":\"Doomscroll\",\"target\":1,\"kind\":\"bad\"}"));
        QCOMPARE(s.habits[0].kind, QStringLiteral("bad"));
        applyEvent(s, mkEvent("habit_slipped", "2026-07-11", 9, "{\"habit_id\":\"b1\",\"date\":\"2026-07-11\"}"));
        QCOMPARE(s.slipTotal, 1);
        QCOMPARE(s.slipByDate.value("2026-07-11"), 1);
        QCOMPARE(s.deeds, 0);          // a slip is not a deed
        QCOMPARE(s.habitLogTotal, 0);  // and isn't a check-in
    }

    void reducer_retireBlob()
    {
        ZooState s;
        applyEvent(s, mkEvent("egg_hatched", "2026-07-11", 9, "{\"id\":\"a\",\"seed\":1,\"rarity\":\"common\"}"));
        applyEvent(s, mkEvent("egg_hatched", "2026-07-11", 9, "{\"id\":\"b\",\"seed\":2,\"rarity\":\"common\"}"));
        QCOMPARE(s.blobs.size(), 2);
        applyEvent(s, mkEvent("egg_retired", "2026-07-11", 9, "{\"id\":\"a\"}"));
        QCOMPARE(s.blobs.size(), 1);
        QCOMPARE(s.blobs[0].id, QStringLiteral("b"));
    }
};

QTEST_GUILESS_MAIN(ZooEngineTest)
#include "tst_main.moc"
