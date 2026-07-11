#include "ZooController.h"
#include "AppId.h"
#include "Rng.h"

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

// Goofy, dry, British challenge pool (subset of data/challenges.json), picked by the day.
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

// The shop of zoo objects. Deliberately useless and fond. Some are also granted at milestones.
struct Deco { const char* id; const char* name; int cost; };
static const Deco kShop[] = {
    { "rock",   "A Suspicious Rock",           15 },
    { "fern",   "A Resilient Fern",            30 },
    { "sign",   "A Passive-Aggressive Sign",   45 },
    { "lamp",   "A Moody Lamp",                60 },
    { "pond",   "A Modest Pond",               90 },
    { "arch",   "An Unnecessary Archway",     140 }
};
static const int kShopCount = int(sizeof(kShop) / sizeof(kShop[0]));

// Goofy "fact of the day" pool (dry, British, entirely unverified).
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
    { "night_owl",  "Small Hours",        "A challenge before 5am.",  "🦉" }
};
static const int kBadgeCount = int(sizeof(kBadges) / sizeof(kBadges[0]));

// ---------------------------------------------------------------------------------------------
ZooController::ZooController(QObject* parent)
    : QObject(parent)
    , m_settings(QLatin1String(AppId::kOrganization), QLatin1String(AppId::kApplication))
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    const QString dbPath = dir + QLatin1Char('/') + QLatin1String(AppId::kDatabaseFile);

    if (!m_store.open(dbPath)) {
        qWarning() << "ZooController: could not open store at" << dbPath;
    } else {
        std::random_device rd;
        const quint64 salt = (static_cast<quint64>(rd()) << 32) ^ static_cast<quint64>(rd());
        m_store.bootstrap(salt);
    }
    recordOpen();
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

// ---- Small JSON helpers ---------------------------------------------------------------------
// Read takes a const& so it works from const getters too; alias kept for readability at call sites.
static QJsonArray readArray(const QSettings& s, const QString& key)
{ return QJsonDocument::fromJson(s.value(key).toString().toUtf8()).array(); }
static QJsonArray readArrayConst(const QSettings& s, const QString& key)
{ return readArray(s, key); }
static void writeArray(QSettings& s, const QString& key, const QJsonArray& a)
{ s.setValue(key, QString::fromUtf8(QJsonDocument(a).toJson(QJsonDocument::Compact))); }

// ---- Identity -------------------------------------------------------------------------------
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

// ---- Economy --------------------------------------------------------------------------------
int ZooController::crumbs() const
{ return m_settings.value(QStringLiteral("crumbs"), 0).toInt(); }

void ZooController::award(int amount, const QString& reason)
{
    m_settings.setValue(QStringLiteral("crumbs"), crumbs() + amount);
    appendNow(QStringLiteral("currency_earned"),
              QStringLiteral("{\"currency\":\"crumbs\",\"amount\":%1,\"reason\":\"%2\"}").arg(amount).arg(reason));
}

bool ZooController::spend(int amount, const QString& reason)
{
    if (crumbs() < amount) return false;
    m_settings.setValue(QStringLiteral("crumbs"), crumbs() - amount);
    appendNow(QStringLiteral("currency_spent"),
              QStringLiteral("{\"currency\":\"crumbs\",\"amount\":%1,\"reason\":\"%2\"}").arg(amount).arg(reason));
    return true;
}

// ---- Daily challenge ------------------------------------------------------------------------
QString ZooController::todayChallenge() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const qint64 ord = d.isValid() ? d.toJulianDay() : 0;
    return QString::fromUtf8(kChallenges[((ord % kChallengeCount) + kChallengeCount) % kChallengeCount]);
}
QString ZooController::todayChallengeStatus() const
{ return m_settings.value(QStringLiteral("challenge/") + localDate(), QStringLiteral("issued")).toString(); }

// ---- Gamification ---------------------------------------------------------------------------
int ZooController::deeds() const
{ return m_settings.value(QStringLiteral("deeds"), 0).toInt(); }

int ZooController::streak() const
{ return m_settings.value(QStringLiteral("streak"), 0).toInt(); }

int ZooController::keeperLevel() const
{
    static const int kThresholds[] = { 0, 3, 8, 16, 30, 50, 80 };
    const int d = deeds();
    int lvl = 0;
    for (int i = 0; i < int(sizeof(kThresholds) / sizeof(kThresholds[0])); ++i)
        if (d >= kThresholds[i]) lvl = i;
    return lvl;
}

QString ZooController::keeperTitle() const
{
    static const char* const kTitles[] = {
        "Volunteer", "Junior Keeper", "Keeper", "Head Keeper", "Curator", "Director",
        "Legendary Director"
    };
    return QString::fromUtf8(kTitles[keeperLevel()]);
}

int ZooController::habitsKeptToday() const
{ return readArrayConst(m_settings, QStringLiteral("habitlog/") + localDate()).size(); }

void ZooController::recordDeed()
{
    m_settings.setValue(QStringLiteral("deeds"), deeds() + 1);
    // Per-day count for the activity graph.
    const QString dayKey = QStringLiteral("deedday/") + localDate();
    m_settings.setValue(dayKey, m_settings.value(dayKey, 0).toInt() + 1);

    const QString today = localDate();
    const QString last = m_settings.value(QStringLiteral("lastActiveDate")).toString();
    if (last != today) {
        const QDate td = QDate::fromString(today, QStringLiteral("yyyy-MM-dd"));
        const QString yesterday = td.isValid()
            ? td.addDays(-1).toString(QStringLiteral("yyyy-MM-dd")) : QString();
        const int st = m_settings.value(QStringLiteral("streak"), 0).toInt();
        m_settings.setValue(QStringLiteral("streak"), (last == yesterday) ? st + 1 : 1);
        m_settings.setValue(QStringLiteral("lastActiveDate"), today);
    }
}

QString ZooController::funFact() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const qint64 ord = d.isValid() ? d.toJulianDay() : 0;
    return QString::fromUtf8(kFacts[((ord % kFactCount) + kFactCount) % kFactCount]);
}

QString ZooController::statusPhrase() const
{
    const int score = (todayChallengeStatus() == QLatin1String("completed") ? 1 : 0)
                    + habitsKeptToday();
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const int pick = int((d.isValid() ? d.toJulianDay() : 0) % 3);
    if (score <= 0) return QString::fromUtf8(kPhraseLow[pick]);
    if (score <= 2) return QString::fromUtf8(kPhraseMid[pick]);
    return QString::fromUtf8(kPhraseHigh[pick]);
}

QVariantList ZooController::badges() const
{
    const int blobs = readArrayConst(m_settings, QStringLiteral("blobs")).size();
    const int deco  = readArrayConst(m_settings, QStringLiteral("decorations")).size();
    const int st    = streak();
    const int hab   = m_settings.value(QStringLiteral("habitLogTotal"), 0).toInt();
    const int quests= m_settings.value(QStringLiteral("questCompletedTotal"), 0).toInt();
    const bool myth = m_settings.value(QStringLiteral("mythicSeen"), false).toBool();
    const bool owl  = m_settings.value(QStringLiteral("nightOwl"), false).toBool();

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
        else if (id == QLatin1String("mythic")) earned = myth;
        else if (id == QLatin1String("night_owl")) earned = owl;

        QVariantMap m;
        m.insert(QStringLiteral("id"), id);
        m.insert(QStringLiteral("name"), QString::fromUtf8(kBadges[i].name));
        m.insert(QStringLiteral("desc"), QString::fromUtf8(kBadges[i].desc));
        m.insert(QStringLiteral("emoji"), QString::fromUtf8(kBadges[i].emoji));
        m.insert(QStringLiteral("earned"), earned);
        out.append(m);
    }
    return out;
}

QVariantList ZooController::activity7() const
{
    QVariantList out;
    const QDate today = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    if (!today.isValid()) { for (int i = 0; i < 7; ++i) out.append(0); return out; }
    for (int i = 6; i >= 0; --i) {
        const QString day = today.addDays(-i).toString(QStringLiteral("yyyy-MM-dd"));
        out.append(m_settings.value(QStringLiteral("deedday/") + day, 0).toInt());
    }
    return out;
}

void ZooController::completeChallenge()
{
    if (todayChallengeStatus() == QLatin1String("completed")) return;
    m_settings.setValue(QStringLiteral("challenge/") + localDate(), QStringLiteral("completed"));
    appendNow(QStringLiteral("challenge_completed"), QStringLiteral("{\"date\":\"%1\"}").arg(localDate()));
    if (m_clock.localHour() < 5)
        m_settings.setValue(QStringLiteral("nightOwl"), true);   // badge flag
    award(15, QStringLiteral("challenge"));
    recordDeed();
    checkMilestones();
    emit stateChanged();
}
void ZooController::skipChallenge()
{
    if (todayChallengeStatus() != QLatin1String("issued")) return;
    m_settings.setValue(QStringLiteral("challenge/") + localDate(), QStringLiteral("skipped"));
    appendNow(QStringLiteral("challenge_skipped"), QStringLiteral("{\"date\":\"%1\"}").arg(localDate()));
    emit stateChanged();
}

// ---- Habits (recurring) ---------------------------------------------------------------------
QVariantList ZooController::habits() const
{
    const QJsonArray defs = readArrayConst(m_settings, QStringLiteral("habits"));
    const QJsonArray doneToday = readArrayConst(m_settings, QStringLiteral("habitlog/") + localDate());
    QVariantList out;
    for (const QJsonValue& v : defs) {
        const QJsonObject o = v.toObject();
        const QString id = o.value(QStringLiteral("id")).toString();
        QVariantMap m;
        m.insert(QStringLiteral("id"), id);
        m.insert(QStringLiteral("name"), o.value(QStringLiteral("name")).toString());
        m.insert(QStringLiteral("doneToday"), doneToday.contains(QJsonValue(id)));
        m.insert(QStringLiteral("lastDone"),
                 m_settings.value(QStringLiteral("habitLast/") + id).toString());
        out.append(m);
    }
    return out;
}
void ZooController::addHabit(const QString& name)
{
    const QString t = name.trimmed();
    if (t.isEmpty()) return;
    QJsonArray defs = readArray(m_settings, QStringLiteral("habits"));
    const QString id = QString::number(QDateTime::currentMSecsSinceEpoch());
    QJsonObject o; o.insert(QStringLiteral("id"), id); o.insert(QStringLiteral("name"), t);
    defs.append(o);
    writeArray(m_settings, QStringLiteral("habits"), defs);
    appendNow(QStringLiteral("habit_created"), QStringLiteral("{\"habit_id\":\"%1\"}").arg(id));
    emit stateChanged();
}
void ZooController::removeHabit(const QString& id)
{
    QJsonArray defs = readArray(m_settings, QStringLiteral("habits"));
    for (int i = 0; i < defs.size(); ++i)
        if (defs.at(i).toObject().value(QStringLiteral("id")).toString() == id) { defs.removeAt(i); break; }
    writeArray(m_settings, QStringLiteral("habits"), defs);
    appendNow(QStringLiteral("habit_archived"), QStringLiteral("{\"habit_id\":\"%1\"}").arg(id));
    emit stateChanged();
}
void ZooController::logHabit(const QString& id)
{
    const QString key = QStringLiteral("habitlog/") + localDate();
    QJsonArray done = readArray(m_settings, key);
    if (done.contains(QJsonValue(id))) return;
    done.append(id);
    writeArray(m_settings, key, done);
    m_settings.setValue(QStringLiteral("habitLogTotal"),
                        m_settings.value(QStringLiteral("habitLogTotal"), 0).toInt() + 1);
    m_settings.setValue(QStringLiteral("habitLast/") + id, localDate());
    appendNow(QStringLiteral("habit_logged"),
              QStringLiteral("{\"habit_id\":\"%1\",\"date\":\"%2\"}").arg(id).arg(localDate()));
    award(5, QStringLiteral("habit"));
    recordDeed();
    checkMilestones();
    emit stateChanged();
}

// ---- Quests (one-off, optional due date) ----------------------------------------------------
QVariantList ZooController::quests() const
{
    const QJsonArray defs = readArrayConst(m_settings, QStringLiteral("quests"));
    QVariantList out;
    for (const QJsonValue& v : defs) {
        const QJsonObject o = v.toObject();
        const QString due = o.value(QStringLiteral("due")).toString();
        QVariantMap m;
        m.insert(QStringLiteral("id"), o.value(QStringLiteral("id")).toString());
        m.insert(QStringLiteral("name"), o.value(QStringLiteral("name")).toString());
        m.insert(QStringLiteral("due"), due);
        m.insert(QStringLiteral("overdue"), !due.isEmpty() && due < localDate());
        out.append(m);
    }
    return out;
}
void ZooController::addQuest(const QString& name, const QString& due)
{
    const QString t = name.trimmed();
    if (t.isEmpty()) return;
    QJsonArray defs = readArray(m_settings, QStringLiteral("quests"));
    const QString id = QString::number(QDateTime::currentMSecsSinceEpoch());
    QJsonObject o; o.insert(QStringLiteral("id"), id); o.insert(QStringLiteral("name"), t);
    o.insert(QStringLiteral("due"), due);
    defs.append(o);
    writeArray(m_settings, QStringLiteral("quests"), defs);
    appendNow(QStringLiteral("quest_created"), QStringLiteral("{\"quest_id\":\"%1\"}").arg(id));
    emit stateChanged();
}
void ZooController::completeQuest(const QString& id)
{
    QJsonArray defs = readArray(m_settings, QStringLiteral("quests"));
    bool found = false;
    for (int i = 0; i < defs.size(); ++i)
        if (defs.at(i).toObject().value(QStringLiteral("id")).toString() == id) { defs.removeAt(i); found = true; break; }
    if (!found) return;
    writeArray(m_settings, QStringLiteral("quests"), defs);
    appendNow(QStringLiteral("quest_completed"), QStringLiteral("{\"quest_id\":\"%1\"}").arg(id));
    m_settings.setValue(QStringLiteral("questCompletedTotal"),
                        m_settings.value(QStringLiteral("questCompletedTotal"), 0).toInt() + 1);
    award(20, QStringLiteral("quest"));   // quests are worth more than a habit check-in
    recordDeed();
    checkMilestones();
    emit stateChanged();
}
void ZooController::removeQuest(const QString& id)
{
    QJsonArray defs = readArray(m_settings, QStringLiteral("quests"));
    for (int i = 0; i < defs.size(); ++i)
        if (defs.at(i).toObject().value(QStringLiteral("id")).toString() == id) { defs.removeAt(i); break; }
    writeArray(m_settings, QStringLiteral("quests"), defs);
    emit stateChanged();
}

// ---- The zoo: hatching blobs ----------------------------------------------------------------
QVariantList ZooController::ownedBlobs() const
{
    const QJsonArray blobs = readArrayConst(m_settings, QStringLiteral("blobs"));
    QVariantList out;
    for (const QJsonValue& v : blobs) {
        const QJsonObject o = v.toObject();
        QVariantMap m;
        m.insert(QStringLiteral("id"), o.value(QStringLiteral("id")).toString());
        m.insert(QStringLiteral("seed"), o.value(QStringLiteral("seed")).toInt());
        m.insert(QStringLiteral("rarity"), o.value(QStringLiteral("rarity")).toString());
        out.append(m);
    }
    return out;
}
void ZooController::hatchBlob()
{
    if (!spend(hatchCost(), QStringLiteral("hatch"))) return;

    QJsonArray blobs = readArray(m_settings, QStringLiteral("blobs"));
    // Seeded, reproducible rarity roll driven by how many we've hatched (spec §5.1).
    Rng r(Rng::mix(m_store.installSalt(), static_cast<quint64>(blobs.size())));
    const double roll = r.nextDouble() * 100.0;
    QString rarity = roll < 1.0 ? QStringLiteral("mythic")
                   : roll < 10.0 ? QStringLiteral("rare")
                   : roll < 36.0 ? QStringLiteral("uncommon")
                                 : QStringLiteral("common");
    const int seed = static_cast<int>(r.next() & 0x7FFFFFFF);
    const QString id = QString::number(QDateTime::currentMSecsSinceEpoch());
    if (rarity == QLatin1String("mythic"))
        m_settings.setValue(QStringLiteral("mythicSeen"), true);   // badge flag

    QJsonObject o;
    o.insert(QStringLiteral("id"), id);
    o.insert(QStringLiteral("seed"), seed);
    o.insert(QStringLiteral("rarity"), rarity);
    blobs.append(o);
    writeArray(m_settings, QStringLiteral("blobs"), blobs);

    appendNow(QStringLiteral("egg_hatched"),
              QStringLiteral("{\"seed\":%1,\"rarity\":\"%2\"}").arg(seed).arg(rarity));
    checkMilestones();
    emit hatched(seed, rarity);
    emit stateChanged();
}

// ---- Shop & decorations ---------------------------------------------------------------------
QVariantList ZooController::shopItems() const
{
    const QJsonArray owned = readArrayConst(m_settings, QStringLiteral("decorations"));
    QVariantList out;
    for (int i = 0; i < kShopCount; ++i) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), QString::fromUtf8(kShop[i].id));
        m.insert(QStringLiteral("name"), QString::fromUtf8(kShop[i].name));
        m.insert(QStringLiteral("cost"), kShop[i].cost);
        m.insert(QStringLiteral("owned"), owned.contains(QJsonValue(QString::fromUtf8(kShop[i].id))));
        out.append(m);
    }
    return out;
}
void ZooController::grantDecoration(const QString& id)
{
    QJsonArray owned = readArray(m_settings, QStringLiteral("decorations"));
    if (owned.contains(QJsonValue(id))) return;
    owned.append(id);
    writeArray(m_settings, QStringLiteral("decorations"), owned);
    appendNow(QStringLiteral("decoration_bought"), QStringLiteral("{\"decoration_id\":\"%1\"}").arg(id));
}
void ZooController::buyObject(const QString& id)
{
    QJsonArray owned = readArray(m_settings, QStringLiteral("decorations"));
    if (owned.contains(QJsonValue(id))) return;
    int cost = -1;
    for (int i = 0; i < kShopCount; ++i)
        if (id == QLatin1String(kShop[i].id)) { cost = kShop[i].cost; break; }
    if (cost < 0) return;
    if (!spend(cost, QStringLiteral("decoration"))) return;
    grantDecoration(id);
    emit stateChanged();
}

// ---- Milestones (grant a decoration once) ---------------------------------------------------
void ZooController::checkMilestones()
{
    QJsonArray granted = readArray(m_settings, QStringLiteral("milestones"));
    auto has = [&](const QString& k) { return granted.contains(QJsonValue(k)); };
    auto mark = [&](const QString& k) { granted.append(k); };

    const int hatched = readArrayConst(m_settings, QStringLiteral("blobs")).size();
    const int habitTotal = m_settings.value(QStringLiteral("habitLogTotal"), 0).toInt();

    bool changed = false;
    if (hatched >= 1 && !has(QStringLiteral("first_hatch"))) {
        grantDecoration(QStringLiteral("rock")); mark(QStringLiteral("first_hatch")); changed = true;
    }
    if (habitTotal >= 7 && !has(QStringLiteral("habit_7"))) {
        grantDecoration(QStringLiteral("fern")); mark(QStringLiteral("habit_7")); changed = true;
    }
    if (changed)
        writeArray(m_settings, QStringLiteral("milestones"), granted);
}

// ---- Log plumbing ---------------------------------------------------------------------------
void ZooController::appendNow(const QString& type, const QString& payload)
{ m_store.appendEvent(type, m_clock.isoUtc(), localDate(), m_clock.localHour(), payload); }

void ZooController::recordOpen()
{ appendNow(QStringLiteral("app_opened"), QStringLiteral("{}")); emit stateChanged(); }

int ZooController::newSeed()
{
    const quint64 s = Rng::mix(m_store.installSalt(), m_seedCounter++);
    Rng r(s);
    return static_cast<int>(r.next() & 0x7FFFFFFF);
}

} // namespace zoo
