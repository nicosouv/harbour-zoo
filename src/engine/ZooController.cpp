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

// A small goofy challenge pool (subset of data/challenges.json). Selected deterministically by the
// day so it's the same for everyone on a given date but changes daily.
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

QString ZooController::localDate() const
{
    return m_clock.localDate();
}

int ZooController::eventCount() const { return m_store.eventCount(); }

QString ZooController::appVersion() const
{
#ifdef APP_VERSION
    return QStringLiteral(APP_VERSION);
#else
    return QStringLiteral("dev");
#endif
}

// ---- Settings-backed identity ---------------------------------------------------------------
bool ZooController::reminderEnabled() const
{ return m_settings.value(QStringLiteral("reminderEnabled"), false).toBool(); }

void ZooController::setReminderEnabled(bool on)
{
    if (on == reminderEnabled()) return;
    m_settings.setValue(QStringLiteral("reminderEnabled"), on);
    emit reminderEnabledChanged();
}

QString ZooController::playerName() const
{ return m_settings.value(QStringLiteral("playerName")).toString(); }

void ZooController::setPlayerName(const QString& name)
{
    if (name == playerName()) return;
    m_settings.setValue(QStringLiteral("playerName"), name);
    emit playerNameChanged();
}

bool ZooController::onboarded() const
{ return m_settings.value(QStringLiteral("onboarded"), false).toBool(); }

void ZooController::setOnboarded(bool on)
{
    if (on == onboarded()) return;
    m_settings.setValue(QStringLiteral("onboarded"), on);
    emit onboardedChanged();
}

// ---- Economy --------------------------------------------------------------------------------
int ZooController::crumbs() const
{ return m_settings.value(QStringLiteral("crumbs"), 0).toInt(); }

void ZooController::award(int amount, const QString& reason)
{
    m_settings.setValue(QStringLiteral("crumbs"), crumbs() + amount);
    appendNow(QStringLiteral("currency_earned"),
              QStringLiteral("{\"currency\":\"crumbs\",\"amount\":%1,\"reason\":\"%2\"}")
                  .arg(amount).arg(reason));
}

// ---- Daily challenge ------------------------------------------------------------------------
QString ZooController::todayChallenge() const
{
    const QDate d = QDate::fromString(localDate(), QStringLiteral("yyyy-MM-dd"));
    const qint64 ord = d.isValid() ? d.toJulianDay() : 0;
    return QString::fromUtf8(kChallenges[((ord % kChallengeCount) + kChallengeCount) % kChallengeCount]);
}

QString ZooController::todayChallengeStatus() const
{
    return m_settings.value(QStringLiteral("challenge/") + localDate(),
                            QStringLiteral("issued")).toString();
}

void ZooController::completeChallenge()
{
    if (todayChallengeStatus() == QLatin1String("completed")) return;
    m_settings.setValue(QStringLiteral("challenge/") + localDate(), QStringLiteral("completed"));
    appendNow(QStringLiteral("challenge_completed"),
              QStringLiteral("{\"date\":\"%1\"}").arg(localDate()));
    award(15, QStringLiteral("challenge"));
    emit stateChanged();
}

void ZooController::skipChallenge()
{
    if (todayChallengeStatus() != QLatin1String("issued")) return;
    m_settings.setValue(QStringLiteral("challenge/") + localDate(), QStringLiteral("skipped"));
    appendNow(QStringLiteral("challenge_skipped"),
              QStringLiteral("{\"date\":\"%1\"}").arg(localDate()));
    emit stateChanged();
}

// ---- Habits ---------------------------------------------------------------------------------
static QJsonArray readArray(QSettings& s, const QString& key)
{
    return QJsonDocument::fromJson(s.value(key).toString().toUtf8()).array();
}
static void writeArray(QSettings& s, const QString& key, const QJsonArray& a)
{
    s.setValue(key, QString::fromUtf8(QJsonDocument(a).toJson(QJsonDocument::Compact)));
}

QVariantList ZooController::habits() const
{
    const QJsonArray defs = QJsonDocument::fromJson(
        m_settings.value(QStringLiteral("habits")).toString().toUtf8()).array();
    const QJsonArray doneToday = QJsonDocument::fromJson(
        m_settings.value(QStringLiteral("habitlog/") + localDate()).toString().toUtf8()).array();

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
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) return;
    QJsonArray defs = readArray(m_settings, QStringLiteral("habits"));
    const QString id = QString::number(QDateTime::currentMSecsSinceEpoch());
    QJsonObject o;
    o.insert(QStringLiteral("id"), id);
    o.insert(QStringLiteral("name"), trimmed);
    defs.append(o);
    writeArray(m_settings, QStringLiteral("habits"), defs);
    appendNow(QStringLiteral("habit_created"),
              QStringLiteral("{\"habit_id\":\"%1\"}").arg(id));
    emit stateChanged();
}

void ZooController::removeHabit(const QString& id)
{
    QJsonArray defs = readArray(m_settings, QStringLiteral("habits"));
    for (int i = 0; i < defs.size(); ++i) {
        if (defs.at(i).toObject().value(QStringLiteral("id")).toString() == id) {
            defs.removeAt(i);
            break;
        }
    }
    writeArray(m_settings, QStringLiteral("habits"), defs);
    appendNow(QStringLiteral("habit_archived"),
              QStringLiteral("{\"habit_id\":\"%1\"}").arg(id));
    emit stateChanged();
}

void ZooController::logHabit(const QString& id)
{
    const QString key = QStringLiteral("habitlog/") + localDate();
    QJsonArray done = readArray(m_settings, key);
    if (done.contains(QJsonValue(id))) return; // already checked in today
    done.append(id);
    writeArray(m_settings, key, done);
    appendNow(QStringLiteral("habit_logged"),
              QStringLiteral("{\"habit_id\":\"%1\",\"date\":\"%2\"}").arg(id).arg(localDate()));
    award(5, QStringLiteral("habit"));
    emit stateChanged();
}

// ---- Log plumbing ---------------------------------------------------------------------------
void ZooController::appendNow(const QString& type, const QString& payload)
{
    m_store.appendEvent(type, m_clock.isoUtc(), localDate(), m_clock.localHour(), payload);
}

void ZooController::recordOpen()
{
    appendNow(QStringLiteral("app_opened"), QStringLiteral("{}"));
    emit stateChanged();
}

int ZooController::newSeed()
{
    const quint64 s = Rng::mix(m_store.installSalt(), m_seedCounter++);
    Rng r(s);
    return static_cast<int>(r.next() & 0x7FFFFFFF);
}

} // namespace zoo
