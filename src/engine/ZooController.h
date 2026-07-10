// Thin QObject facade exposed to QML. Owns the engine's storage and clock and translates between
// QML and the (deterministic, UI-agnostic) services. No business logic lives here — as the engine
// grows (Economy, ChallengeService, StateProjection…) this stays a thin forwarding layer.
#ifndef ZOO_ZOOCONTROLLER_H
#define ZOO_ZOOCONTROLLER_H

#include <QObject>
#include <QSettings>
#include "EventStore.h"
#include "Clock.h"

namespace zoo {

class ZooController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int eventCount READ eventCount NOTIFY stateChanged)
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    Q_PROPERTY(bool reminderEnabled READ reminderEnabled WRITE setReminderEnabled
               NOTIFY reminderEnabledChanged)

public:
    explicit ZooController(QObject* parent = nullptr);

    int eventCount() const;

    // App version (injected via APP_VERSION at build time; "dev" for local/test builds).
    QString appVersion() const;

    // The gentle daily reminder toggle — persisted, OFF by default (design pillar: no nagging).
    bool reminderEnabled() const;
    void setReminderEnabled(bool on);

    // Append an app_opened event (called once at launch).
    Q_INVOKABLE void recordOpen();

    // A fresh, deterministic-per-install seed for a specimen preview. Derived from the install
    // salt + an incrementing counter, so it never touches system RNG. 31-bit so it survives the
    // trip through QML's double-backed JS numbers intact.
    Q_INVOKABLE int newSeed();

signals:
    void stateChanged();
    void reminderEnabledChanged();

private:
    void appendNow(const QString& type, const QString& payload);

    SystemClock m_clock;
    EventStore  m_store;
    QSettings   m_settings;
    quint64     m_seedCounter = 0;
};

} // namespace zoo

#endif // ZOO_ZOOCONTROLLER_H
