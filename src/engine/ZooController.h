// Thin QObject facade exposed to QML. Owns the engine's storage/clock and translates between QML
// and the domain. This prototype keeps loop state in QSettings for speed while ALSO appending to
// the event log, so the proper event-sourced services can replace the QSettings shortcuts later
// without changing the QML.
#ifndef ZOO_ZOOCONTROLLER_H
#define ZOO_ZOOCONTROLLER_H

#include <QObject>
#include <QSettings>
#include <QVariantList>
#include <QTimer>
#include "EventStore.h"
#include "ZooState.h"
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
    Q_PROPERTY(QString playerBirthday READ playerBirthday WRITE setPlayerBirthday NOTIFY playerBirthdayChanged) // "MM-dd"
    Q_PROPERTY(bool onboarded READ onboarded WRITE setOnboarded NOTIFY onboardedChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged) // "" = system
    Q_PROPERTY(QString blobStyle READ blobStyle WRITE setBlobStyle NOTIFY blobStyleChanged) // "mix" or a style id
    Q_PROPERTY(qreal blobScale READ blobScale WRITE setBlobScale NOTIFY blobScaleChanged)   // size multiplier

    Q_PROPERTY(int crumbs READ crumbs NOTIFY stateChanged)
    Q_PROPERTY(int hatchCost READ hatchCost CONSTANT)
    Q_PROPERTY(bool canHatch READ canHatch NOTIFY stateChanged)

    Q_PROPERTY(QString todayChallenge READ todayChallenge NOTIFY stateChanged)
    Q_PROPERTY(QString todayChallengeStatus READ todayChallengeStatus NOTIFY stateChanged)

    // Gamification / status.
    // Pomodoro focus timer — lives in the engine so it survives page navigation.
    Q_PROPERTY(bool focusRunning READ focusRunning NOTIFY focusChanged)
    Q_PROPERTY(int focusRemaining READ focusRemaining NOTIFY focusChanged)  // seconds left
    Q_PROPERTY(int focusMinutes READ focusMinutes NOTIFY focusChanged)      // planned length

    Q_PROPERTY(int deeds READ deeds NOTIFY stateChanged)              // lifetime useful actions
    Q_PROPERTY(int streak READ streak NOTIFY stateChanged)           // consecutive active days
    Q_PROPERTY(int keeperLevel READ keeperLevel NOTIFY stateChanged)
    Q_PROPERTY(QString keeperTitle READ keeperTitle NOTIFY stateChanged)
    Q_PROPERTY(int habitsKeptToday READ habitsKeptToday NOTIFY stateChanged)
    Q_PROPERTY(QString funFact READ funFact NOTIFY stateChanged)         // goofy fact of the day
    Q_PROPERTY(QString statusPhrase READ statusPhrase NOTIFY stateChanged) // adapts to today's effort
    Q_PROPERTY(int todayMood READ todayMood NOTIFY stateChanged)              // emotional check-in 1..5, 0 = none
    Q_PROPERTY(bool moodCheckedToday READ moodCheckedToday NOTIFY stateChanged)
    Q_PROPERTY(QString moodReadiness READ moodReadiness NOTIFY stateChanged)  // adapts the ask to your mood
    Q_PROPERTY(QString gentleNudge READ gentleNudge NOTIFY stateChanged)      // never-miss-twice / welcome back
    Q_PROPERTY(QString freshStartPrompt READ freshStartPrompt NOTIFY stateChanged)
    Q_PROPERTY(QVariantList badges READ badges NOTIFY stateChanged)      // { id, name, desc, emoji, earned }
    Q_PROPERTY(QVariantList activity7 READ activity7 NOTIFY stateChanged) // last 7 days of deed counts
    Q_PROPERTY(QString reflection READ reflection NOTIFY stateChanged)   // quiet self-care line, deepens
    Q_PROPERTY(bool hasUnreadAlmanac READ hasUnreadAlmanac NOTIFY stateChanged) // a new story chapter waits
    Q_PROPERTY(qreal zooMood READ zooMood NOTIFY stateChanged)           // -1..1, from good vs bad habits
    Q_PROPERTY(int weekDeeds READ weekDeeds NOTIFY stateChanged)
    Q_PROPERTY(int monthDeeds READ monthDeeds NOTIFY stateChanged)
    Q_PROPERTY(QString selectedTheme READ selectedTheme NOTIFY stateChanged)
    Q_PROPERTY(QVariantList themes READ themes NOTIFY stateChanged)      // { id, name, cost, owned, selected }

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

    QString playerBirthday() const;              // "MM-dd", empty if unset
    void setPlayerBirthday(const QString& mmdd);

    QString language() const;
    void setLanguage(const QString& code);

    QString blobStyle() const;
    void setBlobStyle(const QString& style);

    qreal blobScale() const;
    void setBlobScale(qreal s);

    // Grant a one-time crumb reward for a hidden easter egg. Returns true if newly claimed.
    Q_INVOKABLE bool claimEasterEgg(const QString& id, int crumbs);

    // Grant crumbs outright (used by the Settings "give me crumbs" testing button).
    Q_INVOKABLE void grantCrumbs(int amount);

    // Ceremonies: celebratory moments surfaced at launch (farewell, milestones, birthday, holiday).
    Q_INVOKABLE QVariantList pendingCeremonies() const;   // [{ id, kind, title, body, emoji, seed }]
    Q_INVOKABLE void dismissCeremony(const QString& id);

    // The Keeper's Almanac: the story's red thread. Chapters unlock at real milestones and reframe,
    // slowly, that the zoo is a portrait of you keeping a promise to yourself ("Le zoo se souvient").
    Q_INVOKABLE QVariantList almanacChapters() const;     // [{ id, index, title, body, unlocked, read }]
    Q_INVOKABLE QVariantMap  pendingChapter() const;      // first unlocked-but-unread chapter, or {}
    Q_INVOKABLE void markChapterRead(const QString& id);
    bool hasUnreadAlmanac() const;                        // an unlocked chapter is waiting to be read

    // Wipe all data (events + preferences) so onboarding runs again. For testing.
    Q_INVOKABLE void resetAll();

    // Testing helpers, wired to the Settings > Testing section. Harmless, deterministic-ish.
    Q_INVOKABLE void debugHatch();          // hatch one blob, free of charge
    Q_INVOKABLE void debugFarewell();       // send the oldest resident off (queues a farewell)
    Q_INVOKABLE void debugBaitPredator();   // drop a quest due yesterday, so the beast eats one
    Q_INVOKABLE void debugBirthday();       // set the birthday to today, to trigger its ceremony

    // Hard cap on residents; hatching beyond it retires the oldest (with a farewell ceremony).
    int blobCap() const { return 20; }

    bool focusRunning() const { return m_focusRunning; }
    int focusRemaining() const { return m_focusRemaining; }
    int focusMinutes() const { return m_focusMinutes; }

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

    // Readiness & behaviour-science nudges (all optional, all gentle).
    Q_INVOKABLE void logMood(int valence);   // emotional check-in, smiley 1..5
    int todayMood() const;                   // 0 if not checked in yet today
    bool moodCheckedToday() const;
    QString moodReadiness() const;           // adapts the app's ask to how you feel
    QString gentleNudge() const;             // "never miss twice" / warm welcome-back
    QString freshStartPrompt() const;        // week/month boundary renegotiation prompt
    QVariantList badges() const;
    QVariantList activity7() const;
    QString reflection() const;
    qreal zooMood() const;
    int weekDeeds() const;
    int monthDeeds() const;
    QString selectedTheme() const;
    QVariantList themes() const;
    QVariantList habits() const;
    QVariantList quests() const;
    QVariantList ownedBlobs() const;
    QVariantList shopItems() const;

    Q_INVOKABLE void recordOpen();
    Q_INVOKABLE int  newSeed();

    // Daily loop (each rewards Crumbs and records an event).
    Q_INVOKABLE void completeChallenge();
    Q_INVOKABLE void skipChallenge();
    // kind = good|bad. cue = implementation intention/anchor; replacement + tolerated apply to bad
    // habits (a same-reward swap, and bounded indulgence that spares the zoo mood). All optional.
    Q_INVOKABLE void addHabit(const QString& name, int target, const QString& kind,
                              const QString& cue = QString(), const QString& replacement = QString(),
                              bool tolerated = false);
    Q_INVOKABLE void removeHabit(const QString& id);
    Q_INVOKABLE void logHabit(const QString& id);                 // one check-in toward the target

    // Quests: one-off tasks, optional due date (yyyy-MM-dd, "" if none). Bigger Crumb reward.
    Q_INVOKABLE void addQuest(const QString& name, const QString& due);
    Q_INVOKABLE void completeQuest(const QString& id);
    Q_INVOKABLE void removeQuest(const QString& id);

    // Each overdue quest costs one resident (eaten by the Quest Beast), once. Returns the eaten
    // blobs' seeds so the UI can play the predator animation. Call once at launch.
    Q_INVOKABLE QVariantList processOverdueQuests();

    // The zoo: spend Crumbs to hatch a blob into the collection; buy decorations & biomes.
    Q_INVOKABLE void hatchBlob();
    Q_INVOKABLE void buyObject(const QString& id);
    Q_INVOKABLE void buyTheme(const QString& id);
    Q_INVOKABLE void selectTheme(const QString& id);

    // Pomodoro: start/stop from QML; the engine ticks and rewards on completion.
    Q_INVOKABLE void startFocus(int minutes);
    Q_INVOKABLE void stopFocus();

signals:
    void stateChanged();
    void reminderEnabledChanged();
    void playerNameChanged();
    void playerBirthdayChanged();
    void onboardedChanged();
    void languageChanged();
    void blobStyleChanged();
    void blobScaleChanged();
    void focusChanged();
    void focusFinished(int minutes);   // for a celebratory UI moment (confetti)
    void hatched(int seed, const QString& rarity);   // for a celebratory UI moment

private:
    // Append an event to the log AND fold it into m_state. The single way state ever changes.
    void emitEvent(const QString& type, const QString& payload);
    void replay();                                    // rebuild m_state from snapshot + tail
    void migrateIfNeeded();                            // seed a 'migrated' event from old QSettings
    void maybeSnapshot();                              // bound the log: snapshot + prune periodically

    void award(int amount, const QString& reason);
    bool spend(int amount, const QString& reason);    // false if unaffordable
    void grantDecoration(const QString& id);
    void checkMilestones();
    bool almanacUnlocked(int index) const;            // has story chapter `index` been earned yet
    void finishFocus();                               // called by the tick when the timer hits 0
    QString localDate() const;

    SystemClock m_clock;
    EventStore  m_store;
    QSettings   m_settings;                            // device preferences only (not game state)
    ZooState    m_state;                               // the projection: fold of the event log
    quint64     m_seedCounter = 0;
    int         m_eventsSinceSnapshot = 0;

    QTimer m_focusTimer;
    bool   m_focusRunning = false;
    int    m_focusRemaining = 0;
    int    m_focusMinutes = 0;
};

} // namespace zoo

#endif // ZOO_ZOOCONTROLLER_H
