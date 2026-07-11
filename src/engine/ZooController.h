// Thin QObject facade exposed to QML. Owns the engine's storage/clock and translates between QML
// and the domain. This prototype keeps loop state in QSettings for speed while ALSO appending to
// the event log, so the proper event-sourced services can replace the QSettings shortcuts later
// without changing the QML.
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

    Q_PROPERTY(QString playerName READ playerName WRITE setPlayerName NOTIFY playerNameChanged)
    Q_PROPERTY(bool onboarded READ onboarded WRITE setOnboarded NOTIFY onboardedChanged)

    Q_PROPERTY(int crumbs READ crumbs NOTIFY stateChanged)
    Q_PROPERTY(int hatchCost READ hatchCost CONSTANT)
    Q_PROPERTY(bool canHatch READ canHatch NOTIFY stateChanged)

    Q_PROPERTY(QString todayChallenge READ todayChallenge NOTIFY stateChanged)
    Q_PROPERTY(QString todayChallengeStatus READ todayChallengeStatus NOTIFY stateChanged)

    // Gamification / status.
    Q_PROPERTY(int deeds READ deeds NOTIFY stateChanged)              // lifetime useful actions
    Q_PROPERTY(int streak READ streak NOTIFY stateChanged)           // consecutive active days
    Q_PROPERTY(int keeperLevel READ keeperLevel NOTIFY stateChanged)
    Q_PROPERTY(QString keeperTitle READ keeperTitle NOTIFY stateChanged)
    Q_PROPERTY(int habitsKeptToday READ habitsKeptToday NOTIFY stateChanged)
    Q_PROPERTY(QString funFact READ funFact NOTIFY stateChanged)         // goofy fact of the day
    Q_PROPERTY(QString statusPhrase READ statusPhrase NOTIFY stateChanged) // adapts to today's effort
    Q_PROPERTY(QVariantList badges READ badges NOTIFY stateChanged)      // { id, name, desc, emoji, earned }
    Q_PROPERTY(QVariantList activity7 READ activity7 NOTIFY stateChanged) // last 7 days of deed counts

    Q_PROPERTY(QVariantList habits READ habits NOTIFY stateChanged)       // { id, name, doneToday }
    Q_PROPERTY(QVariantList quests READ quests NOTIFY stateChanged)       // { id, name, due, overdue }
    Q_PROPERTY(QVariantList ownedBlobs READ ownedBlobs NOTIFY stateChanged)   // { id, seed, rarity }
    Q_PROPERTY(QVariantList shopItems READ shopItems NOTIFY stateChanged)     // { id, name, cost, owned }

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
    int hatchCost() const { return 25; }
    bool canHatch() const { return crumbs() >= hatchCost(); }

    QString todayChallenge() const;
    QString todayChallengeStatus() const;
    int deeds() const;
    int streak() const;
    int keeperLevel() const;
    QString keeperTitle() const;
    int habitsKeptToday() const;
    QString funFact() const;
    QString statusPhrase() const;
    QVariantList badges() const;
    QVariantList activity7() const;
    QVariantList habits() const;
    QVariantList quests() const;
    QVariantList ownedBlobs() const;
    QVariantList shopItems() const;

    Q_INVOKABLE void recordOpen();
    Q_INVOKABLE int  newSeed();

    // Daily loop (each rewards Crumbs and records an event).
    Q_INVOKABLE void completeChallenge();
    Q_INVOKABLE void skipChallenge();
    Q_INVOKABLE void addHabit(const QString& name);
    Q_INVOKABLE void removeHabit(const QString& id);
    Q_INVOKABLE void logHabit(const QString& id);

    // Quests: one-off tasks, optional due date (yyyy-MM-dd, "" if none). Bigger Crumb reward.
    Q_INVOKABLE void addQuest(const QString& name, const QString& due);
    Q_INVOKABLE void completeQuest(const QString& id);
    Q_INVOKABLE void removeQuest(const QString& id);

    // The zoo: spend Crumbs to hatch a blob into the collection; buy decorations.
    Q_INVOKABLE void hatchBlob();
    Q_INVOKABLE void buyObject(const QString& id);

signals:
    void stateChanged();
    void reminderEnabledChanged();
    void playerNameChanged();
    void onboardedChanged();
    void hatched(int seed, const QString& rarity);   // for a celebratory UI moment

private:
    void appendNow(const QString& type, const QString& payload);
    void award(int amount, const QString& reason);
    bool spend(int amount, const QString& reason);   // false if unaffordable
    void grantDecoration(const QString& id);
    void checkMilestones();
    void recordDeed();                                // bump lifetime deeds + active-day streak
    QString localDate() const;

    SystemClock m_clock;
    EventStore  m_store;
    QSettings   m_settings;
    quint64     m_seedCounter = 0;
};

} // namespace zoo

#endif // ZOO_ZOOCONTROLLER_H
