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

void ZooController::completeChallenge()
{
    if (todayChallengeStatus() == QLatin1String("completed")) return;
    m_settings.setValue(QStringLiteral("challenge/") + localDate(), QStringLiteral("completed"));
    appendNow(QStringLiteral("challenge_completed"), QStringLiteral("{\"date\":\"%1\"}").arg(localDate()));
    award(15, QStringLiteral("challenge"));
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
    appendNow(QStringLiteral("habit_logged"),
              QStringLiteral("{\"habit_id\":\"%1\",\"date\":\"%2\"}").arg(id).arg(localDate()));
    award(5, QStringLiteral("habit"));
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
    award(20, QStringLiteral("quest"));   // quests are worth more than a habit check-in
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
