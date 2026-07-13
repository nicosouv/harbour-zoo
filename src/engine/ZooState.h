// The projected game state: the fold of the event log. Plain data, no behaviour. Everything here
// is reconstructed deterministically by replaying events through applyEvent() (see StateProjection).
// Device *preferences* (language, blob style, reminder…) are NOT here — they live in QSettings.
#ifndef ZOO_ZOOSTATE_H
#define ZOO_ZOOSTATE_H

#include <QString>
#include <QList>
#include <QSet>
#include <QMap>

namespace zoo {

struct Habit {
    QString id; QString name; int target = 1; QString kind = QStringLiteral("good"); // good|bad
    QString cue;               // implementation intention / anchor ("after coffee, at my desk")
    QString replacement;       // for bad habits: a swap that gives the same reward
    QString toleratedUntil;    // bounded indulgence: date ("yyyy-MM-dd") the tolerance window ends.
                               // Empty = not tolerated. Slips inside the window spare the zoo mood;
                               // once it passes, the app gently re-asks (extend or let it count).
};
struct Quest { QString id; QString name; QString due; };
struct Blob  { QString id; int seed = 0; QString rarity; QString date; };

struct ZooState {
    int crumbs = 0;

    QList<Habit> habits;
    QList<Quest> quests;
    QList<Blob>  blobs;

    QSet<QString> decorations;   // owned decoration ids
    QSet<QString> themesOwned;   // owned biome ids ("night" is implicit)
    QSet<QString> eggsClaimed;   // one-time easter-egg ids

    QMap<QString, int>     habitCount;      // key "date/id" -> check-ins/slips that day
    QMap<QString, QString> habitLast;       // id -> last date logged
    QMap<QString, int>     deedByDate;      // date -> useful-actions that day (activity graph)
    QMap<QString, int>     slipByDate;      // date -> bad-habit slips that day (zoo mood)
    QMap<QString, QString> challengeStatus; // date -> "completed" | "skipped"
    QMap<QString, int>     moodByDate;      // date -> latest emotional check-in valence (1..5)

    int slipTotal = 0;
    int moodLogTotal = 0;

    int habitLogTotal = 0;
    int questCompletedTotal = 0;
    int focusTotal = 0;
    int retiredTotal = 0;        // lifetime residents that have set off for good (farewells)
    int deeds = 0;               // lifetime useful actions
    int streak = 0;              // consecutive active days
    QString lastActiveDate;
    bool mythicSeen = false;
    bool nightOwl = false;
};

} // namespace zoo

#endif // ZOO_ZOOSTATE_H
