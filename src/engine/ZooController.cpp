#include "ZooController.h"
#include "AppId.h"
#include "Rng.h"

#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <random>

namespace zoo {

ZooController::ZooController(QObject* parent)
    : QObject(parent)
{
    // Store lives under the app's writable data location.
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    const QString dbPath = dir + QLatin1Char('/') + QLatin1String(AppId::kDatabaseFile);

    if (!m_store.open(dbPath)) {
        qWarning() << "ZooController: could not open store at" << dbPath;
        return;
    }

    // Generate a permanent install salt on first run (impure, once). std::random_device is fine
    // here because it seeds the deterministic world exactly once; everything downstream is derived.
    std::random_device rd;
    const quint64 salt = (static_cast<quint64>(rd()) << 32) ^ static_cast<quint64>(rd());
    m_store.bootstrap(salt);

    recordOpen();
}

int ZooController::eventCount() const
{
    return m_store.eventCount();
}

void ZooController::appendNow(const QString& type, const QString& payload)
{
    m_store.appendEvent(type, m_clock.isoUtc(), m_clock.localDate(), m_clock.localHour(), payload);
    emit stateChanged();
}

void ZooController::recordOpen()
{
    appendNow(QStringLiteral("app_opened"), QStringLiteral("{}"));
}

int ZooController::newSeed()
{
    const quint64 s = Rng::mix(m_store.installSalt(), m_seedCounter++);
    Rng r(s);
    return static_cast<int>(r.next() & 0x7FFFFFFF);
}

} // namespace zoo
