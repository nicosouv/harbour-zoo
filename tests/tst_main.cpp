// Engine unit tests, runnable on plain desktop Qt5 (no device/SDK). Covers the two foundations:
// deterministic RNG and the append-only EventStore round-trip + install-salt persistence.
#include <QtTest>
#include <QSet>

#include "engine/Rng.h"
#include "engine/EventStore.h"
#include "engine/Clock.h"

using namespace zoo;

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
};

QTEST_GUILESS_MAIN(ZooEngineTest)
#include "tst_main.moc"
