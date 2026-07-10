// Thin QObject facade exposed to QML. Owns the engine's storage/clock and translates between QML
// and the domain. This prototype keeps the loop's state in QSettings for speed while ALSO appending
// to the event log, so the proper event-sourced services (Economy, HabitService, ChallengeService,
// StateProjection) can replace the QSettings shortcuts later without changing the QML.
#ifndef ZOO_ZOOCONTROLLER_H
#define ZOO_ZOOCONTROLLER_H

#include <QObject>
#include <QSettings>
#include <QVariantList>
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

    // Identity & onboarding.
    Q_PROPERTY(QString playerName READ playerName WRITE setPlayerName NOTIFY playerNameChanged)
    Q_PROPERTY(bool onboarded READ onboarded WRITE setOnboarded NOTIFY onboardedChanged)

    // Economy.
    Q_PROPERTY(int crumbs READ crumbs NOTIFY stateChanged)

    // Daily challenge.
    Q_PROPERTY(QString todayChallenge READ todayChallenge NOTIFY stateChanged)
    Q_PROPERTY(QString todayChallengeStatus READ todayChallengeStatus NOTIFY stateChanged)

    // Habits: each entry is { id, name, doneToday }.
    Q_PROPERTY(QVariantList habits READ habits NOTIFY stateChanged)

public:
    explicit ZooController(QObject* parent = nullptr);

    int eventCount() const;
    QString appVersion() const;

    bool reminderEnabled() const;
    void setReminderEnabled(bool on);

    QString playerName() const;
    void setPlayerName(const QString& name);

    bool onboarded() const;
    void setOnboarded(bool on);

    int crumbs() const;

    QString todayChallenge() const;
    QString todayChallengeStatus() const;   // "issued" | "completed" | "skipped"
    QVariantList habits() const;

    Q_INVOKABLE void recordOpen();
    Q_INVOKABLE int  newSeed();

    // The daily loop (each rewards Crumbs and records an event).
    Q_INVOKABLE void completeChallenge();
    Q_INVOKABLE void skipChallenge();
    Q_INVOKABLE void addHabit(const QString& name);
    Q_INVOKABLE void removeHabit(const QString& id);
    Q_INVOKABLE void logHabit(const QString& id);   // check-in for today

signals:
    void stateChanged();
    void reminderEnabledChanged();
    void playerNameChanged();
    void onboardedChanged();

private:
    void appendNow(const QString& type, const QString& payload);
    void award(int amount, const QString& reason);
    QString localDate() const;

    SystemClock m_clock;
    EventStore  m_store;
    QSettings   m_settings;
    quint64     m_seedCounter = 0;
};

} // namespace zoo

#endif // ZOO_ZOOCONTROLLER_H
