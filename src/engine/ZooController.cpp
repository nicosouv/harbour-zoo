#include "ZooController.h"
#include "AppId.h"
#include "Rng.h"
#include "StateProjection.h"

#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QDate>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDateTime>
#include <random>

namespace zoo {

// ---- static catalogs (not state — just content) ---------------------------------------------
static const char* const kChallenges[] = {
    "Introduce yourself to a cloud. Keep it professional.",
    "Compliment an inanimate object out loud. Mean it.",
    "Photograph three triangular things. They know what they did.",
    "Name a pigeon. Do NOT tell it its name. It must never know.",
    "Walk somewhere you've never walked. Ten whole metres counts.",
    "Do your best impression of a door. Nobody's watching. Probably.",
    "Find a face in something that isn't a face. Say hi. Be normal about it.",
    "Hum a dramatic theme for a boring task. Commit like your life depends on it.",
    "Reorganise something by colour for absolutely no reason.",
    "Thank a tool that helped you today. Out loud. Yes, really.",
    "Invent a word for how you feel right now. Use it once, aggressively.",
    "Stand like a superhero for one full breath. Feel the power. Leave."
};
static const int kChallengeCount = int(sizeof(kChallenges) / sizeof(kChallenges[0]));

struct Deco { const char* id; const char* name; int cost; };
static const Deco kShop[] = {
    { "rock",    "A Suspicious Rock",           15 }, { "fern",    "A Resilient Fern",            30 },
    { "sign",    "A Passive-Aggressive Sign",   45 }, { "lamp",    "A Moody Lamp",                60 },
    { "pond",    "A Modest Pond",               90 }, { "arch",    "An Unnecessary Archway",     140 },
    { "statue",  "A Statue of Nobody",         120 }, { "balloon", "A Single Sad Balloon",        35 },
    { "gnome",   "An Off-Duty Gnome",           70 }, { "swing",   "A Creaky Swing",             100 },
    { "totem",   "A Totem of Mild Power",      180 }, { "fountain","A Fountain, Allegedly",      220 }
};
static const int kShopCount = int(sizeof(kShop) / sizeof(kShop[0]));

struct Biome { const char* id; const char* name; int cost; };
static const Biome kThemes[] = {
    { "night", "Night (default)", 0 }, { "grass", "Meadow", 40 }, { "desert", "Desert", 60 },
    { "farwest", "Far West", 90 }, { "cyberpunk", "Neon City", 140 }, { "snow", "Quiet Snow", 80 },
    { "tokyo", "Tokyo Street", 160 }
};
static const int kThemeCount = int(sizeof(kThemes) / sizeof(kThemes[0]));

static const char* const kFacts[] = {
    "A group of blobs is called a 'mild concern'.",
    "No blob has ever finished a to-do list. They find it aspirational.",
    "The average blob blinks four times before deciding you're fine.",
    "Every blob believes it is slightly larger than it actually is.",
    "Blobs hop to think. They think rarely.",
    "A blob's favourite colour is 'the grey one'.",
    "Statistically, you are someone's favourite. The blobs took a vote.",
    "Blobs do not dream. They simply buffer.",
    "It is considered rude to count a blob's pixels aloud.",
    "Blobs are 90% vibes and 10% structural concern.",
    "The oldest known blob is three weeks old and unbearably smug.",
    "Crumbs aren't currency anywhere reputable. Here, they're everything.",
    "Blobs experience Tuesdays more intensely than other creatures.",
    "The word 'blep' predates language. Probably."
};
static const int kFactCount = int(sizeof(kFacts) / sizeof(kFacts[0]));

static const char* const kPhraseLow[] = {
    "You've done precisely nothing today. Magnificent restraint.",
    "A blank slate. The blobs are pretending not to notice.",
    "Nothing yet. Bold. We admire the commitment to leisure."
};
static const char* const kPhraseMid[] = {
    "A start. The blobs are cautiously optimistic.",
    "Some progress. Steady on, hero.",
    "Not bad. The zoo noticed and will deny it later."
};
static const char* const kPhraseHigh[] = {
    "Look at you. Insufferable, honestly.",
    "Fully productive. The blobs are a little intimidated.",
    "All done. Please leave some ambition for tomorrow."
};

struct Badge { const char* id; const char* name; const char* desc; const char* emoji; };
static const Badge kBadges[] = {
    { "first_blob", "Hatchling",          "Hatch your first blob.",   "🥚" },
    { "menagerie",  "Menagerie",          "Five residents.",          "🐾" },
    { "streak3",    "Consistent-ish",     "A 3-day streak.",          "🔥" },
    { "streak7",    "Regular",            "A 7-day streak.",          "🔥" },
    { "habitual",   "Creature of Habit",  "Ten habit check-ins.",     "📋" },
    { "questgiver", "Quest Cleared",      "Finish five quests.",      "🗺️" },
    { "collector",  "Interior Decorator", "Own three objects.",       "🪴" },
    { "mythic",     "Impossible Colour",  "Hatch a mythic blob.",     "✨" },
    { "night_owl",  "Small Hours",        "A challenge before 5am.",  "🦉" },
    { "regular",    "Regular Attender",   "25 useful things done.",   "📈" },
    { "devotee",    "Devotee",            "100 useful things done.",  "🏆" },
    { "fortnight",  "Fortnight",          "A 14-day streak.",         "📆" },
    { "full_house", "Full House",         "Ten residents.",           "🏠" },
    { "quest_master","Quest Master",      "Finish ten quests.",       "⚔️" },
    { "landscaper", "Landscaper",         "Own three biomes.",        "🗺️" },
    { "ritualist",  "Ritualist",          "Thirty habit check-ins.",  "🔁" },
    { "focused",    "Focused",            "Five focus sessions.",     "⏳" },
    { "tended",     "Well-Tended",        "A 7-day streak with 20 habits. You are being looked after.", "🫶" }
};
static const int kBadgeCount = int(sizeof(kBadges) / sizeof(kBadges[0]));

// A few national holidays per language (goofy ceremonies trigger on these dates).
struct Holiday { const char* lang; const char* mmdd; const char* name; };
static const Holiday kHolidays[] = {
    { "fr", "07-14", "le 14 juillet" }, { "fr", "01-01", "le Nouvel An" }, { "fr", "12-25", "Noël" },
    { "de", "10-03", "Tag der Deutschen Einheit" }, { "de", "12-25", "Weihnachten" },
    { "it", "06-02", "Festa della Repubblica" }, { "it", "12-25", "Natale" },
    { "es", "10-12", "Fiesta Nacional" }, { "es", "12-25", "Navidad" },
    { "fi", "12-06", "itsenäisyyspäivä" }, { "fi", "12-25", "joulu" },
    { "en", "12-25", "Christmas" }, { "en", "01-01", "New Year's Day" }, { "en", "10-31", "Halloween" },
    { "",   "12-25", "Christmas" }, { "",   "01-01", "New Year's Day" }
};
static const int kHolidayCount = int(sizeof(kHolidays) / sizeof(kHolidays[0]));
static QString holidayName(const QString& lang, const QString& mmdd)
{
    for (int i = 0; i < kHolidayCount; ++i)
        if (mmdd == QLatin1String(kHolidays[i].mmdd) && lang == QLatin1String(kHolidays[i].lang))
            return QString::fromUtf8(kHolidays[i].name);
    return QString();
}

static QString jpayload(const QJsonObject& o)
{ return QString::fromUtf8(QJsonDocument(o).toJson(QJsonDocument::Compact)); }

// ---------------------------------------------------------------------------------------------
ZooController::ZooController(QObject* parent)
    : QObject(parent)
    , m_settings(QLatin1String(AppId::kOrganization), QLatin1String(AppId::kApplication))
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    if (!m_store.open(dir + QLatin1Char('/') + QLatin1String(AppId::kDatabaseFile))) {
        qWarning() << "ZooController: could not open store";
    } else {
        std::random_device rd;
        const quint64 salt = (static_cast<quint64>(rd()) << 32) ^ static_cast<quint64>(rd());
        m_store.bootstrap(salt);
    }

    m_focusTimer.setInterval(1000);
    connect(&m_focusTimer, &QTimer::timeout, this, [this]() {
        if (!m_focusRunning) return;
        if (--m_focusRemaining <= 0) { finishFocus(); return; }
        emit focusChanged();
    });

    migrateIfNeeded();
    replay();
    emit stateChanged();
}

QString ZooController::localDate() const { return m_clock.localDate(); }
int ZooController::eventCount() const { return m_store.eventCount(); }

QString ZooController::appVersion() const
{
#ifdef APP_VERSION
    return QStringLiteral(APP_VERSION);
#else
    return QStringLiteral("dev");
#endif
}

// ---- event plumbing -------------------------------------------------------------------------
void ZooController::emitEvent(const QString& type, const QString& payload)
{
    Event e;
    e.type = type;
    e.tsUtc = m_clock.isoUtc();
    e.localDate = m_clock.localDate();
    e.localHour = m_clock.localHour();
    e.payload = payload;
    e.seq = m_store.appendEvent(type, e.tsUtc, e.localDate, e.localHour, payload);
    applyEvent(m_state, e);
    maybeSnapshot();
}

void ZooController::replay()
{
    ZooState s;
    qint64 asOf = 0;
    QString snap;
    if (m_store.loadSnapshot(asOf, snap) && !snap.isEmpty())
        s = fromJson(QJsonDocument::fromJson(snap.toUtf8()).object());
    const QVector<Event> evs = m_store.events();
    for (const Event& e : evs)
        if (e.seq > asOf) applyEvent(s, e);   // 'migrated' events reset state as they fold
    m_state = s;
}

void ZooController::maybeSnapshot()
{
    if (++m_eventsSinceSnapshot < 250) return;   // bound the log to a few hundred events
    m_eventsSinceSnapshot = 0;
    const qint64 seq = m_store.maxSeq();
    if (seq <= 0) return;
    m_store.saveSnapshot(seq, jpayload(toJson(m_state)));
    m_store.pruneEventsBefore(seq);
}

void ZooController::migrateIfNeeded()
{
    if (m_settings.value(QStringLiteral("esMigrated"), false).toBool()) return;
    m_settings.setValue(QStringLiteral("esMigrated"), true);
    if (!m_settings.contains(QStringLiteral("crumbs")) && !m_settings.contains(QStringLiteral("habits"))
        && !m_settings.contains(QStringLiteral("blobs")))
        return; // fresh install, nothing to bring across

    const QString today = localDate();
    ZooState s;
    s.crumbs = m_settings.value(QStringLiteral("crumbs"), 0).toInt();

    for (const QJsonValue& v : QJsonDocument::fromJson(m_settings.value(QStringLiteral("habits")).toString().toUtf8()).array()) {
        const QJsonObject o = v.toObject();
        Habit h; h.id = o.value("id").toString(); h.name = o.value("name").toString();
        h.target = qMax(1, o.value("target").toInt(1));
        s.habits.append(h);
        s.habitLast[h.id] = m_settings.value(QStringLiteral("habitLast/") + h.id).toString();
        const int c = m_settings.value(QStringLiteral("hc/") + today + '/' + h.id, 0).toInt();
        if (c > 0) s.habitCount[today + '/' + h.id] = c;
    }
    for (const QJsonValue& v : QJsonDocument::fromJson(m_settings.value(QStringLiteral("quests")).toString().toUtf8()).array()) {
        const QJsonObject o = v.toObject();
        Quest q; q.id = o.value("id").toString(); q.name = o.value("name").toString(); q.due = o.value("due").toString();
        s.quests.append(q);
    }
    for (const QJsonValue& v : QJsonDocument::fromJson(m_settings.value(QStringLiteral("blobs")).toString().toUtf8()).array()) {
        const QJsonObject o = v.toObject();
        Blob b; b.id = o.value("id").toString(); b.seed = o.value("seed").toInt();
        b.rarity = o.value("rarity").toString(); b.date = o.value("date").toString();
        s.blobs.append(b);
    }
    for (const QJsonValue& v : QJsonDocument::fromJson(m_settings.value(QStringLiteral("decorations")).toString().toUtf8()).array())
        s.decorations.insert(v.toString());
    for (const QJsonValue& v : QJsonDocument::fromJson(m_settings.value(QStringLiteral("themes")).toString().toUtf8()).array())
        s.themesOwned.insert(v.toString());
    s.habitLogTotal = m_settings.value(QStringLiteral("habitLogTotal"), 0).toInt();
    s.questCompletedTotal = m_settings.value(QStringLiteral("questCompletedTotal"), 0).toInt();
    s.focusTotal = m_settings.value(QStringLiteral("focusTotal"), 0).toInt();
    s.deeds = m_settings.value(QStringLiteral("deeds"), 0).toInt();
    s.streak = m_settings.value(QStringLiteral("streak"), 0).toInt();
    s.lastActiveDate = m_settings.value(QStringLiteral("lastActiveDate")).toString();
    s.mythicSeen = m_settings.value(QStringLiteral("mythicSeen"), false).toBool();
    s.nightOwl = m_settings.value(QStringLiteral("nightOwl"), false).toBool();
    if (m_settings.value(QStringLiteral("egg/funfact"), false).toBool()) s.eggsClaimed.insert(QStringLiteral("funfact"));
    if (m_settings.value(QStringLiteral("egg/reflection"), false).toBool()) s.eggsClaimed.insert(QStringLiteral("reflection"));
    const QDate td = QDate::fromString(today, QStringLiteral("yyyy-MM-dd"));
    if (td.isValid()) for (int i = 0; i < 7; ++i) {
        const QString d = td.addDays(-i).toString(QStringLiteral("yyyy-MM-dd"));
        const int c = m_settings.value(QStringLiteral("deedday/") + d, 0).toInt();
        if (c > 0) s.deedByDate[d] = c;
    }
    const QString cs = m_settings.value(QStringLiteral("challenge/") + today).toString();
    if (!cs.isEmpty()) s.challengeStatus[today] = cs;

    emitEvent(QStringLiteral("migrated"), jpayload(toJson(s)));
}

// ---- preferences (QSettings) ----------------------------------------------------------------
bool ZooController::reminderEnabled() const
{ return m_settings.value(QStringLiteral("reminderEnabled"), false).toBool(); }
void ZooController::setReminderEnabled(bool on)
{ if (on == reminderEnabled()) return; m_settings.setValue(QStringLiteral("reminderEnabled"), on); emit reminderEnabledChanged(); }

QString ZooController::playerName() const
{ return m_settings.value(QStringLiteral("playerName")).toString(); }
void ZooController::setPlayerName(const QString& name)
{ if (name == playerName()) return; m_settings.setValue(QStringLiteral("playerName"), name); emit playerNameChanged(); }

bool ZooController::onboarded() const
{ return m_settings.value(QStringLiteral("onboarded"), false).toBool(); }
void ZooController::setOnboarded(bool on)
{ if (on == onboarded()) return; m_settings.setValue(QStringLiteral("onboarded"), on); emit onboardedChanged(); }

QString ZooController::playerBirthday() const
{ return m_settings.value(QStringLiteral("playerBirthday")).toString(); }
void ZooController::setPlayerBirthday(const QString& mmdd)
{ if (mmdd == playerBirthday()) return; m_settings.setValue(QStringLiteral("playerBirthday"), mmdd); emit playerBirthdayChanged(); }

QString ZooController::language() const
{ return m_settings.value(QStringLiteral("language")).toString(); }
void ZooController::setLanguage(const QString& code)
{ if (code == language()) return; m_settings.setValue(QStringLiteral("language"), code); emit languageChanged(); }

QString ZooController::blobStyle() const
{ return m_settings.value(QStringLiteral("blobStyle"), QStringLiteral("mix")).toString(); }
void ZooController::setBlobStyle(const QString& style)
{ if (style == blobStyle()) return; m_settings.setValue(QStringLiteral("blobStyle"), style); emit blobStyleChanged(); }

qreal ZooController::blobScale() const
{ return m_settings.value(QStringLiteral("blobScale"), 1.0).toReal(); }
void ZooController::setBlobScale(qreal s)
{
    if (s < 0.5) s = 0.5; if (s > 2.0) s = 2.0;
    if (qFuzzyCompare(s, blobScale())) return;
    m_settings.setValue(QStringLiteral("blobScale"), s);
    emit blobScaleChanged();
}

QString ZooController::selectedTheme() const
{ return m_settings.value(QStringLiteral("selectedTheme"), QStringLiteral("night")).toString(); }

// ---- economy (events) -----------------------------------------------------------------------
int ZooController::crumbs() const { return m_state.crumbs; }

void ZooController::award(int amount, const QString& reason)
{
    QJsonObject o; o.insert("currency", "crumbs"); o.insert("amount", amount); o.insert("reason", reason);
    emitEvent(QStringLiteral("currency_earned"), jpayload(o));
}
bool ZooController::spend(int amount, const QString& reason)
{
    if (m_state.crumbs < amount) return false;
    QJsonObject o; o.insert("currency", "crumbs"); o.insert("amount", amount); o.insert("reason", reason);
    emitEvent(QStringLiteral("currency_spent"), jpayload(o));
    return true;
}
void ZooController::grantCrumbs(int amount)
{ if (amount <= 0) return; award(amount, QStringLiteral("grant")); emit stateChanged(); }

bool ZooController::claimEasterEgg(const QString& id, int crumbs)
{
    if (m_state.eggsClaimed.contains(id)) return false;
    QJsonObject o; o.insert("id", id); o.insert("crumbs", crumbs);
    emitEvent(QStringLiteral("egg_claimed"), jpayload(o));
    emit stateChanged();
    return true;
}

// ---- ceremonies -----------------------------------------------------------------------------
QVariantList ZooController::pendingCeremonies() const
{
    QVariantList out;
    const QString today = localDate();
    const QString mmdd = today.size() >= 10 ? today.mid(5) : QString();
    const QString year = today.left(4);
    auto shown = [this](const QString& id) {
        return m_settings.value(QStringLiteral("ceremonyShown/") + id, false).toBool();
    };

    const QJsonArray fs = QJsonDocument::fromJson(m_settings.value(QStringLiteral("pendingFarewells")).toString().toUtf8()).array();
    for (const QJsonValue& v : fs) {
        const int seed = v.toObject().value("seed").toInt();
        QVariantMap m;
        m.insert("id", QStringLiteral("farewell/") + QString::number(seed));
        m.insert("kind", QStringLiteral("farewell"));
        m.insert("title", tr("A fond farewell"));
        m.insert("body", tr("A blob grew up and set off to live its own life. Not because you failed it — "
                            "because it was ready. The zoo remembers."));
        m.insert("emoji", QStringLiteral("👋"));
        m.insert("seed", seed);
        out.append(m);
    }

    static const int kMs[] = { 25, 50, 100, 200 };
    for (int i = 0; i < int(sizeof(kMs) / sizeof(kMs[0])); ++i) {
        const QString id = QStringLiteral("habit/") + QString::number(kMs[i]);
        if (m_state.habitLogTotal >= kMs[i] && !shown(id)) {
            QVariantMap m;
            m.insert("id", id); m.insert("kind", QStringLiteral("milestone"));
            m.insert("title", tr("Well kept"));
            m.insert("body", tr("%1 habit check-ins. The blobs are quietly proud, and a little competitive.").arg(kMs[i]));
            m.insert("emoji", QStringLiteral("🎉"));
            out.append(m);
        }
    }

    const QString bd = playerBirthday();
    if (!bd.isEmpty() && bd == mmdd) {
        const QString id = QStringLiteral("birthday/") + year;
        if (!shown(id)) {
            QVariantMap m;
            m.insert("id", id); m.insert("kind", QStringLiteral("birthday"));
            m.insert("title", tr("Happy birthday"));
            m.insert("body", tr("The whole zoo made you something. It's a blob. It's always a blob."));
            m.insert("emoji", QStringLiteral("🎂"));
            out.append(m);
        }
    }

    const QString hol = holidayName(language(), mmdd);
    if (!hol.isEmpty()) {
        const QString id = QStringLiteral("holiday/") + year + '/' + mmdd;
        if (!shown(id)) {
            QVariantMap m;
            m.insert("id", id); m.insert("kind", QStringLiteral("holiday"));
            m.insert("title", hol);
            m.insert("body", tr("The zoo is closed for celebrations. The blobs are wearing tiny hats."));
            m.insert("emoji", QStringLiteral("🎊"));
            out.append(m);
        }
    }
    return out;
}

void ZooController::dismissCeremony(const QString& id)
{
    if (id.startsWith(QStringLiteral("farewell/"))) {
        const int seed = id.mid(9).toInt();
        const QJsonArray fs = QJsonDocument::fromJson(m_settings.value(QStringLiteral("pendingFarewells")).toString().toUtf8()).array();
        QJsonArray keep;
        for (const QJsonValue& v : fs) if (v.toObject().value("seed").toInt() != seed) keep.append(v);
        m_settings.setValue(QStringLiteral("pendingFarewells"),
                            QString::fromUtf8(QJsonDocument(keep).toJson(QJsonDocument::Compact)));
    } else {
        m_settings.setValue(QStringLiteral("ceremonyShown/") + id, true);
    }
    emit stateChanged();
}

// The Keeper's Almanac — the story's red thread ("Le zoo se souvient"). Told in the Curator's
// voice, in four movements (arrival · the everyday · the turn · the reveal): the zoo is not a
// collection of creatures, it is a portrait of one person who kept a small promise to themselves.
// Chapters unlock at real milestones; "read" is a preference (like ceremonyShown), not game state.
struct AlmanacChapter { const char* id; const char* title; const char* body; };
static const AlmanacChapter kAlmanac[] = {
    { "arrival",
      QT_TR_NOOP("The empty zoo"),
      QT_TR_NOOP("It was empty when you found it — a few bare enclosures, the wind, and a ring of keys "
                 "nobody had claimed. You picked them up. Nothing here is anything yet. That is the very "
                 "best time to begin.") },
    { "first_light",
      QT_TR_NOOP("The first light"),
      QT_TR_NOOP("A handful of ordinary days, and already something stirs in the grass. You didn't build "
                 "a creature; you kept a small promise, and the creature came to keep you company. Keep "
                 "coming back. It watches the gate.") },
    { "companions",
      QT_TR_NOOP("Company"),
      QT_TR_NOOP("There's a little crowd now — each one a day you chose yourself over the easier nothing. "
                 "They don't know they're a calendar. They think they're a family. Let them.") },
    { "the_seat",
      QT_TR_NOOP("The seat, kept warm"),
      QT_TR_NOOP("Seven days you turned up. A day will slip one day — it always does — and when it does, "
                 "the gate stays open and your seat stays warm. This zoo counts arrivals, never absences. "
                 "Coming back is the only rule there is.") },
    { "first_goodbye",
      QT_TR_NOOP("The first goodbye"),
      QT_TR_NOOP("One of them shouldered a little bundle and walked out the gate for good. It didn't leave "
                 "because you failed it. It left because it had finally grown enough to. That small ache? "
                 "That is proof it mattered. The things we tend outgrow us. Let it be the happy ending it is.") },
    { "the_turn",
      QT_TR_NOOP("What the zoo was for"),
      QT_TR_NOOP("You thought you were collecting creatures. Look again. Every enclosure is a Tuesday you "
                 "didn't waste, a promise to yourself quietly kept. The zoo was never the point. It was "
                 "only ever the proof.") },
    { "the_promise",
      QT_TR_NOOP("A zoo built from Tuesdays"),
      QT_TR_NOOP("Here is the whole secret, now that you've earned it: none of this was ever about the "
                 "blobs. It was about someone who kept showing up for themselves, one small day at a time, "
                 "until the showing-up became who they are. That someone is you. The zoo only ever "
                 "remembered it back to you.") }
};
static const int kAlmanacCount = int(sizeof(kAlmanac) / sizeof(kAlmanac[0]));

// Whether chapter `i` has been unlocked by the current state. Thresholds are gentle and roughly
// monotonic, so the story reveals itself in order as the zoo (and its Keeper) grows.
bool ZooController::almanacUnlocked(int i) const
{
    const int blobs = m_state.blobs.size();
    switch (i) {
    case 0: return blobs >= 1 || m_state.deeds >= 1;              // arrival
    case 1: return m_state.deeds >= 5;                            // first light
    case 2: return blobs >= 5;                                    // company
    case 3: return m_state.streak >= 7;                           // the seat
    case 4: return m_state.retiredTotal >= 1;                     // first goodbye
    case 5: return m_state.deeds >= 25 || keeperLevel() >= 3;     // the turn
    case 6: return m_state.deeds >= 100 || blobs >= 20;           // the promise
    default: return false;
    }
}

QVariantList ZooController::almanacChapters() const
{
    QVariantList out;
    for (int i = 0; i < kAlmanacCount; ++i) {
        const QString id = QString::fromUtf8(kAlmanac[i].id);
        const bool unlocked = almanacUnlocked(i);
        QVariantMap m;
        m.insert("id", id);
        m.insert("index", i + 1);
        m.insert("unlocked", unlocked);
        m.insert("read", m_settings.value(QStringLiteral("almanacRead/") + id, false).toBool());
        // Locked chapters read as a gentle promise, never their contents (no spoilers).
        m.insert("title", unlocked ? tr(kAlmanac[i].title) : tr("Not yet written"));
        m.insert("body", unlocked ? tr(kAlmanac[i].body)
                                  : tr("The Almanac keeps this page blank, for now. Keep showing up."));
        out.append(m);
    }
    return out;
}

QVariantMap ZooController::pendingChapter() const
{
    for (int i = 0; i < kAlmanacCount; ++i) {
        const QString id = QString::fromUtf8(kAlmanac[i].id);
        if (!almanacUnlocked(i)) continue;
        if (m_settings.value(QStringLiteral("almanacRead/") + id, false).toBool()) continue;
        QVariantMap m;
        m.insert("id", id);
        m.insert("index", i + 1);
        m.insert("title", tr(kAlmanac[i].title));
        m.insert("body", tr(kAlmanac[i].body));
        return m;   // earliest unlocked-but-unread: surfaces the story in order, one page at a time
    }
    return QVariantMap();
}

void ZooController::markChapterRead(const QString& id)
{
    m_settings.setValue(QStringLiteral("almanacRead/") + id, true);
    emit stateChanged();
}

bool ZooController::hasUnreadAlmanac() const
{
    for (int i = 0; i < kAlmanacCount; ++i) {
        if (!almanacUnlocked(i)) continue;
        const QString id = QString::fromUtf8(kAlmanac[i].id);
        if (!m_settings.value(QStringLiteral("almanacRead/") + id, false).toBool()) return true;
    }
    return false;
}

void ZooController::resetAll()
{
    m_store.clearAll();
    m_settings.clear();
    m_settings.setValue(QStringLiteral("esMigrated"), true);   // nothing left to migrate
    m_state = ZooState();
    m_eventsSinceSnapshot = 0;
    emit stateChanged();
    emit onboardedChanged();
    emit playerNameChanged();
    emit playerBirthdayChanged();
    emit blobStyleChanged();
    emit blobScaleChanged();
    emit reminderEnabledChanged();
    emit languageChanged();
}

// ---- testing helpers ------------------------------------------------------------------------
void ZooController::debugHatch()
{
    grantCrumbs(hatchCost());   // pay for it, then hatch through the normal path (cap/farewell/milestones)
    hatchBlob();
}

void ZooController::debugFarewell()
{
    if (m_state.blobs.isEmpty()) return;
    const Blob oldest = m_state.blobs.first();
    QJsonObject rr; rr.insert("id", oldest.id);
    emitEvent(QStringLiteral("egg_retired"), jpayload(rr));
    QJsonArray fs = QJsonDocument::fromJson(m_settings.value(QStringLiteral("pendingFarewells")).toString().toUtf8()).array();
    QJsonObject f; f.insert("seed", oldest.seed);
    fs.append(f);
    m_settings.setValue(QStringLiteral("pendingFarewells"),
                        QString::fromUtf8(QJsonDocument(fs).toJson(QJsonDocument::Compact)));
    emit stateChanged();
}

void ZooController::debugBaitPredator()
{
    const QDate today = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const QString due = (today.isValid() ? today.addDays(-1) : QDate::currentDate().addDays(-1))
                            .toString(QStringLiteral("yyyy-MM-dd"));
    addQuest(QStringLiteral("Beast bait"), due);   // overdue on the next zoo visit
}

void ZooController::debugBirthday()
{
    const QString today = localDate();
    if (today.size() >= 10) setPlayerBirthday(today.mid(5));   // "MM-dd"
}

// ---- daily challenge ------------------------------------------------------------------------
QString ZooController::todayChallenge() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const qint64 ord = d.isValid() ? d.toJulianDay() : 0;
    return tr(kChallenges[((ord % kChallengeCount) + kChallengeCount) % kChallengeCount]);
}
QString ZooController::todayChallengeStatus() const
{ return m_state.challengeStatus.value(localDate(), QStringLiteral("issued")); }

void ZooController::completeChallenge()
{
    if (todayChallengeStatus() == QLatin1String("completed")) return;
    QJsonObject o; o.insert("date", localDate());
    emitEvent(QStringLiteral("challenge_completed"), jpayload(o));
    award(15, QStringLiteral("challenge"));
    checkMilestones();
    emit stateChanged();
}
void ZooController::skipChallenge()
{
    if (todayChallengeStatus() != QLatin1String("issued")) return;
    QJsonObject o; o.insert("date", localDate());
    emitEvent(QStringLiteral("challenge_skipped"), jpayload(o));
    emit stateChanged();
}

// ---- habits ---------------------------------------------------------------------------------
QVariantList ZooController::habits() const
{
    const QString today = localDate();
    QVariantList out;
    for (const Habit& h : m_state.habits) {
        const int cnt = m_state.habitCount.value(today + '/' + h.id, 0);
        const bool bad = (h.kind == QLatin1String("bad"));
        QVariantMap m;
        m.insert("id", h.id); m.insert("name", h.name); m.insert("target", h.target);
        m.insert("kind", h.kind); m.insert("bad", bad);
        m.insert("doneCount", cnt);
        // Good habits are "done" when the target is met; bad habits are "clean" when never ticked.
        m.insert("doneToday", bad ? (cnt == 0) : (cnt >= h.target));
        m.insert("slips", cnt);
        m.insert("lastDone", m_state.habitLast.value(h.id));
        out.append(m);
    }
    return out;
}
void ZooController::addHabit(const QString& name, int target, const QString& kind)
{
    const QString t = name.trimmed();
    if (t.isEmpty()) return;
    QJsonObject o; o.insert("id", QString::number(QDateTime::currentMSecsSinceEpoch()));
    o.insert("name", t); o.insert("target", qMax(1, target));
    o.insert("kind", kind == QLatin1String("bad") ? "bad" : "good");
    emitEvent(QStringLiteral("habit_created"), jpayload(o));
    emit stateChanged();
}
void ZooController::removeHabit(const QString& id)
{
    QJsonObject o; o.insert("id", id);
    emitEvent(QStringLiteral("habit_archived"), jpayload(o));
    emit stateChanged();
}
void ZooController::logHabit(const QString& id)
{
    int target = 1;
    bool bad = false;
    for (const Habit& h : m_state.habits) if (h.id == id) { target = h.target; bad = (h.kind == QLatin1String("bad")); break; }

    QJsonObject o; o.insert("habit_id", id); o.insert("date", localDate());
    if (bad) {
        // Ticking a bad habit is a slip: recorded, no reward, no deed. Never shamed.
        emitEvent(QStringLiteral("habit_slipped"), jpayload(o));
        emit stateChanged();
        return;
    }
    const int cur = m_state.habitCount.value(localDate() + '/' + id, 0);
    if (cur >= target) return;
    emitEvent(QStringLiteral("habit_logged"), jpayload(o));
    award(5, QStringLiteral("habit"));
    checkMilestones();
    emit stateChanged();
}

// ---- quests ---------------------------------------------------------------------------------
QVariantList ZooController::quests() const
{
    const QString today = localDate();
    QVariantList out;
    for (const Quest& q : m_state.quests) {
        QVariantMap m;
        m.insert("id", q.id); m.insert("name", q.name); m.insert("due", q.due);
        m.insert("overdue", !q.due.isEmpty() && q.due < today);
        out.append(m);
    }
    return out;
}
void ZooController::addQuest(const QString& name, const QString& due)
{
    const QString t = name.trimmed();
    if (t.isEmpty()) return;
    QJsonObject o; o.insert("id", QString::number(QDateTime::currentMSecsSinceEpoch()));
    o.insert("name", t); o.insert("due", due);
    emitEvent(QStringLiteral("quest_created"), jpayload(o));
    emit stateChanged();
}
void ZooController::completeQuest(const QString& id)
{
    bool found = false;
    for (const Quest& q : m_state.quests) if (q.id == id) { found = true; break; }
    if (!found) return;
    QJsonObject o; o.insert("id", id);
    emitEvent(QStringLiteral("quest_completed"), jpayload(o));
    award(20, QStringLiteral("quest"));
    checkMilestones();
    emit stateChanged();
}
void ZooController::removeQuest(const QString& id)
{
    QJsonObject o; o.insert("id", id);
    emitEvent(QStringLiteral("quest_removed"), jpayload(o));
    emit stateChanged();
}

QVariantList ZooController::processOverdueQuests()
{
    QVariantList out;
    const QString today = localDate();
    for (int i = 0; i < m_state.quests.size(); ++i) {
        const Quest q = m_state.quests[i];
        if (q.due.isEmpty() || q.due >= today) continue;                          // not overdue
        if (m_settings.value(QStringLiteral("predated/") + q.id, false).toBool()) continue; // already cost a blob
        if (m_state.blobs.isEmpty()) break;                                       // nothing left to eat
        m_settings.setValue(QStringLiteral("predated/") + q.id, true);
        const Blob victim = m_state.blobs.first();
        QJsonObject o; o.insert("id", victim.id);
        emitEvent(QStringLiteral("egg_retired"), jpayload(o));                    // the beast eats it
        QVariantMap m; m.insert("seed", victim.seed);
        out.append(m);
    }
    if (!out.isEmpty()) emit stateChanged();
    return out;
}

// ---- the zoo --------------------------------------------------------------------------------
QVariantList ZooController::ownedBlobs() const
{
    QVariantList out;
    for (const Blob& b : m_state.blobs) {
        QVariantMap m;
        m.insert("id", b.id); m.insert("seed", b.seed); m.insert("rarity", b.rarity); m.insert("date", b.date);
        out.append(m);
    }
    return out;
}
void ZooController::hatchBlob()
{
    if (m_state.crumbs < hatchCost()) return;
    Rng r(Rng::mix(m_store.installSalt(), static_cast<quint64>(m_state.blobs.size())));
    const double roll = r.nextDouble() * 100.0;
    const QString rarity = roll < 1.0 ? QStringLiteral("mythic") : roll < 10.0 ? QStringLiteral("rare")
                         : roll < 36.0 ? QStringLiteral("uncommon") : QStringLiteral("common");
    const int seed = static_cast<int>(r.next() & 0x7FFFFFFF);

    if (!spend(hatchCost(), QStringLiteral("hatch"))) return;

    // At the cap, the oldest resident retires for new adventures (a farewell ceremony is queued).
    if (m_state.blobs.size() >= blobCap() && !m_state.blobs.isEmpty()) {
        const Blob oldest = m_state.blobs.first();
        QJsonObject rr; rr.insert("id", oldest.id);
        emitEvent(QStringLiteral("egg_retired"), jpayload(rr));
        QJsonArray fs = QJsonDocument::fromJson(m_settings.value(QStringLiteral("pendingFarewells")).toString().toUtf8()).array();
        QJsonObject f; f.insert("seed", oldest.seed);
        fs.append(f);
        m_settings.setValue(QStringLiteral("pendingFarewells"),
                            QString::fromUtf8(QJsonDocument(fs).toJson(QJsonDocument::Compact)));
    }

    QJsonObject o; o.insert("id", QString::number(QDateTime::currentMSecsSinceEpoch()));
    o.insert("seed", seed); o.insert("rarity", rarity); o.insert("date", localDate());
    emitEvent(QStringLiteral("egg_hatched"), jpayload(o));
    checkMilestones();
    emit hatched(seed, rarity);
    emit stateChanged();
}

QVariantList ZooController::shopItems() const
{
    QVariantList out;
    for (int i = 0; i < kShopCount; ++i) {
        const QString id = QString::fromUtf8(kShop[i].id);
        QVariantMap m;
        m.insert("id", id); m.insert("name", tr(kShop[i].name)); m.insert("cost", kShop[i].cost);
        m.insert("owned", m_state.decorations.contains(id));
        out.append(m);
    }
    return out;
}
void ZooController::grantDecoration(const QString& id)
{
    if (m_state.decorations.contains(id)) return;
    QJsonObject o; o.insert("decoration_id", id);
    emitEvent(QStringLiteral("decoration_bought"), jpayload(o));
}
void ZooController::buyObject(const QString& id)
{
    if (m_state.decorations.contains(id)) return;
    int cost = -1;
    for (int i = 0; i < kShopCount; ++i) if (id == QLatin1String(kShop[i].id)) { cost = kShop[i].cost; break; }
    if (cost < 0 || !spend(cost, QStringLiteral("decoration"))) return;
    grantDecoration(id);
    emit stateChanged();
}

// ---- biomes ---------------------------------------------------------------------------------
QVariantList ZooController::themes() const
{
    const QString sel = selectedTheme();
    QVariantList out;
    for (int i = 0; i < kThemeCount; ++i) {
        const QString id = QString::fromUtf8(kThemes[i].id);
        const bool owned = (id == QLatin1String("night")) || m_state.themesOwned.contains(id);
        QVariantMap m;
        m.insert("id", id); m.insert("name", tr(kThemes[i].name)); m.insert("cost", kThemes[i].cost);
        m.insert("owned", owned); m.insert("selected", id == sel);
        out.append(m);
    }
    return out;
}
void ZooController::buyTheme(const QString& id)
{
    if (id == QLatin1String("night") || m_state.themesOwned.contains(id)) return;
    int cost = -1;
    for (int i = 0; i < kThemeCount; ++i) if (id == QLatin1String(kThemes[i].id)) { cost = kThemes[i].cost; break; }
    if (cost < 0 || !spend(cost, QStringLiteral("biome"))) return;
    QJsonObject o; o.insert("biome_id", id);
    emitEvent(QStringLiteral("biome_bought"), jpayload(o));
    m_settings.setValue(QStringLiteral("selectedTheme"), id);   // wear it now (preference)
    emit stateChanged();
}
void ZooController::selectTheme(const QString& id)
{
    if (id != QLatin1String("night") && !m_state.themesOwned.contains(id)) return;
    if (id == selectedTheme()) return;
    m_settings.setValue(QStringLiteral("selectedTheme"), id);
    emit stateChanged();
}

// ---- gamification (derived from state) ------------------------------------------------------
int ZooController::deeds() const { return m_state.deeds; }
int ZooController::streak() const { return m_state.streak; }

int ZooController::keeperLevel() const
{
    static const int kThresholds[] = { 0, 3, 8, 16, 30, 50, 80 };
    int lvl = 0;
    for (int i = 0; i < int(sizeof(kThresholds) / sizeof(kThresholds[0])); ++i)
        if (m_state.deeds >= kThresholds[i]) lvl = i;
    return lvl;
}
QString ZooController::keeperTitle() const
{
    static const char* const kTitles[] = {
        "Volunteer", "Junior Keeper", "Keeper", "Head Keeper", "Curator", "Director", "Legendary Director"
    };
    return tr(kTitles[keeperLevel()]);
}
int ZooController::habitsKeptToday() const
{
    const QString pref = localDate() + '/';
    int total = 0;
    for (auto it = m_state.habitCount.begin(); it != m_state.habitCount.end(); ++it)
        if (it.key().startsWith(pref)) total += it.value();
    return total;
}

QString ZooController::funFact() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const qint64 ord = d.isValid() ? d.toJulianDay() : 0;
    return tr(kFacts[((ord % kFactCount) + kFactCount) % kFactCount]);
}
QString ZooController::statusPhrase() const
{
    const int score = (todayChallengeStatus() == QLatin1String("completed") ? 1 : 0) + habitsKeptToday();
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const int pick = int((d.isValid() ? d.toJulianDay() : 0) % 3);
    if (score <= 0) return tr(kPhraseLow[pick]);
    if (score <= 2) return tr(kPhraseMid[pick]);
    return tr(kPhraseHigh[pick]);
}

QVariantList ZooController::badges() const
{
    const int blobs = m_state.blobs.size();
    const int deco = m_state.decorations.size();
    const int dd = m_state.deeds, st = m_state.streak;
    const int hab = m_state.habitLogTotal, quests = m_state.questCompletedTotal, focus = m_state.focusTotal;
    const int biomes = m_state.themesOwned.size() + 1;
    QVariantList out;
    for (int i = 0; i < kBadgeCount; ++i) {
        const QString id = QString::fromUtf8(kBadges[i].id);
        bool earned = false;
        if (id == QLatin1String("first_blob")) earned = blobs >= 1;
        else if (id == QLatin1String("menagerie")) earned = blobs >= 5;
        else if (id == QLatin1String("streak3")) earned = st >= 3;
        else if (id == QLatin1String("streak7")) earned = st >= 7;
        else if (id == QLatin1String("habitual")) earned = hab >= 10;
        else if (id == QLatin1String("questgiver")) earned = quests >= 5;
        else if (id == QLatin1String("collector")) earned = deco >= 3;
        else if (id == QLatin1String("mythic")) earned = m_state.mythicSeen;
        else if (id == QLatin1String("night_owl")) earned = m_state.nightOwl;
        else if (id == QLatin1String("regular")) earned = dd >= 25;
        else if (id == QLatin1String("devotee")) earned = dd >= 100;
        else if (id == QLatin1String("fortnight")) earned = st >= 14;
        else if (id == QLatin1String("full_house")) earned = blobs >= 10;
        else if (id == QLatin1String("quest_master")) earned = quests >= 10;
        else if (id == QLatin1String("landscaper")) earned = biomes >= 3;
        else if (id == QLatin1String("ritualist")) earned = hab >= 30;
        else if (id == QLatin1String("focused")) earned = focus >= 5;
        else if (id == QLatin1String("tended")) earned = st >= 7 && hab >= 20;

        QVariantMap m;
        m.insert("id", id); m.insert("name", tr(kBadges[i].name)); m.insert("desc", tr(kBadges[i].desc));
        m.insert("emoji", QString::fromUtf8(kBadges[i].emoji)); m.insert("earned", earned);
        out.append(m);
    }
    return out;
}

QVariantList ZooController::activity7() const
{
    QVariantList out;
    const QDate today = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    if (!today.isValid()) { for (int i = 0; i < 7; ++i) out.append(0); return out; }
    for (int i = 6; i >= 0; --i)
        out.append(m_state.deedByDate.value(today.addDays(-i).toString(QStringLiteral("yyyy-MM-dd")), 0));
    return out;
}

QString ZooController::reflection() const
{
    const int n = m_state.blobs.size();
    if (n <= 0) return QString();
    if (n < 3)  return tr("Every creature here is a day you showed up.");
    if (n < 6)  return tr("The zoo fills as you do the small things. Funny, that.");
    if (n < 10) return tr("A collection of ordinary days, quietly kept.");
    if (n < 20) return tr("Turns out this is what looking after yourself looks like.");
    return tr("A whole zoo, built from Tuesdays. You did that. On purpose, even.");
}

qreal ZooController::zooMood() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    if (!d.isValid()) return 0.0;
    int good = 0, slip = 0;
    for (int i = 0; i < 7; ++i) {
        const QString day = d.addDays(-i).toString(QStringLiteral("yyyy-MM-dd"));
        good += m_state.deedByDate.value(day, 0);
        slip += m_state.slipByDate.value(day, 0);
    }
    if (good + slip == 0) return 0.0;
    qreal m = qreal(good - slip) / qreal(good + slip + 3);
    if (m < -1.0) m = -1.0;
    if (m > 1.0) m = 1.0;
    return m;
}
int ZooController::weekDeeds() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    if (!d.isValid()) return 0;
    int total = 0;
    for (int i = 0; i < 7; ++i) total += m_state.deedByDate.value(d.addDays(-i).toString(QStringLiteral("yyyy-MM-dd")), 0);
    return total;
}
int ZooController::monthDeeds() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    if (!d.isValid()) return 0;
    int total = 0;
    for (int i = 0; i < 30; ++i) total += m_state.deedByDate.value(d.addDays(-i).toString(QStringLiteral("yyyy-MM-dd")), 0);
    return total;
}

void ZooController::checkMilestones()
{
    if (m_state.blobs.size() >= 1 && !m_state.decorations.contains(QStringLiteral("rock")))
        grantDecoration(QStringLiteral("rock"));
    if (m_state.habitLogTotal >= 7 && !m_state.decorations.contains(QStringLiteral("fern")))
        grantDecoration(QStringLiteral("fern"));
}

// ---- focus (pomodoro) — engine-driven -------------------------------------------------------
void ZooController::startFocus(int minutes)
{
    if (minutes <= 0) return;
    m_focusMinutes = minutes; m_focusRemaining = minutes * 60; m_focusRunning = true;
    m_focusTimer.start();
    emit focusChanged();
}
void ZooController::stopFocus()
{
    if (!m_focusRunning && m_focusRemaining == 0) return;
    m_focusTimer.stop(); m_focusRunning = false; m_focusRemaining = 0;
    emit focusChanged();
}
void ZooController::finishFocus()
{
    m_focusTimer.stop();
    const int minutes = m_focusMinutes;
    m_focusRunning = false; m_focusRemaining = 0;
    QJsonObject o; o.insert("minutes", minutes);
    emitEvent(QStringLiteral("focus_completed"), jpayload(o));
    award(2 + minutes / 5, QStringLiteral("focus"));
    checkMilestones();
    emit focusChanged();
    emit focusFinished(minutes);
    emit stateChanged();
}

// ---- misc -----------------------------------------------------------------------------------
void ZooController::recordOpen() { emit stateChanged(); }

int ZooController::newSeed()
{
    const quint64 s = Rng::mix(m_store.installSalt(), m_seedCounter++);
    Rng r(s);
    return static_cast<int>(r.next() & 0x7FFFFFFF);
}

} // namespace zoo
