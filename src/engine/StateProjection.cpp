#include "StateProjection.h"

#include <QJsonDocument>
#include <QJsonArray>
#include <QDate>

namespace zoo {

// A "useful action" happened on `date`: bump lifetime deeds, the per-day count, and the streak.
static void recordDeed(ZooState& s, const QString& date)
{
    s.deeds += 1;
    s.deedByDate[date] = s.deedByDate.value(date, 0) + 1;
    if (date != s.lastActiveDate) {
        const QDate d = QDate::fromString(date, QStringLiteral("yyyy-MM-dd"));
        const QString yest = d.isValid() ? d.addDays(-1).toString(QStringLiteral("yyyy-MM-dd")) : QString();
        s.streak = (s.lastActiveDate == yest && !s.lastActiveDate.isEmpty()) ? s.streak + 1 : 1;
        s.lastActiveDate = date;
    }
}

static void removeById(QList<Habit>& v, const QString& id)
{ for (int i = 0; i < v.size(); ++i) if (v[i].id == id) { v.removeAt(i); return; } }
static void removeById(QList<Quest>& v, const QString& id)
{ for (int i = 0; i < v.size(); ++i) if (v[i].id == id) { v.removeAt(i); return; } }
static void removeById(QList<Blob>& v, const QString& id)
{ for (int i = 0; i < v.size(); ++i) if (v[i].id == id) { v.removeAt(i); return; } }

void applyEvent(ZooState& s, const Event& e)
{
    const QJsonObject p = QJsonDocument::fromJson(e.payload.toUtf8()).object();
    const QString& t = e.type;

    if (t == QLatin1String("currency_earned")) {
        s.crumbs += p.value(QStringLiteral("amount")).toInt();
    } else if (t == QLatin1String("currency_spent")) {
        s.crumbs -= p.value(QStringLiteral("amount")).toInt();
    } else if (t == QLatin1String("challenge_completed")) {
        s.challengeStatus[e.localDate] = QStringLiteral("completed");
        if (e.localHour < 5) s.nightOwl = true;
        recordDeed(s, e.localDate);
    } else if (t == QLatin1String("challenge_skipped")) {
        s.challengeStatus[e.localDate] = QStringLiteral("skipped");
    } else if (t == QLatin1String("habit_created")) {
        Habit h;
        h.id = p.value(QStringLiteral("id")).toString();
        h.name = p.value(QStringLiteral("name")).toString();
        h.target = qMax(1, p.value(QStringLiteral("target")).toInt(1));
        const QString k = p.value(QStringLiteral("kind")).toString();
        h.kind = (k == QLatin1String("bad")) ? QStringLiteral("bad") : QStringLiteral("good");
        s.habits.append(h);
    } else if (t == QLatin1String("habit_archived")) {
        removeById(s.habits, p.value(QStringLiteral("id")).toString());
    } else if (t == QLatin1String("habit_logged")) {
        const QString id = p.value(QStringLiteral("habit_id")).toString();
        QString d = p.value(QStringLiteral("date")).toString();
        if (d.isEmpty()) d = e.localDate;
        const QString key = d + QLatin1Char('/') + id;
        s.habitCount[key] = s.habitCount.value(key, 0) + 1;
        s.habitLogTotal += 1;
        s.habitLast[id] = d;
        recordDeed(s, d);
    } else if (t == QLatin1String("habit_slipped")) {
        // A "bad" habit was ticked (you did the thing you meant to avoid). No reward, no deed —
        // just a quietly-recorded slip that nudges the zoo's mood.
        const QString id = p.value(QStringLiteral("habit_id")).toString();
        QString d = p.value(QStringLiteral("date")).toString();
        if (d.isEmpty()) d = e.localDate;
        const QString key = d + QLatin1Char('/') + id;
        s.habitCount[key] = s.habitCount.value(key, 0) + 1;
        s.slipByDate[d] = s.slipByDate.value(d, 0) + 1;
        s.slipTotal += 1;
        s.habitLast[id] = d;
    } else if (t == QLatin1String("quest_created")) {
        Quest q;
        q.id = p.value(QStringLiteral("id")).toString();
        q.name = p.value(QStringLiteral("name")).toString();
        q.due = p.value(QStringLiteral("due")).toString();
        s.quests.append(q);
    } else if (t == QLatin1String("quest_completed")) {
        removeById(s.quests, p.value(QStringLiteral("id")).toString());
        s.questCompletedTotal += 1;
        recordDeed(s, e.localDate);
    } else if (t == QLatin1String("quest_removed")) {
        removeById(s.quests, p.value(QStringLiteral("id")).toString());
    } else if (t == QLatin1String("egg_hatched")) {
        Blob b;
        b.id = p.value(QStringLiteral("id")).toString();
        b.seed = p.value(QStringLiteral("seed")).toInt();
        b.rarity = p.value(QStringLiteral("rarity")).toString();
        b.date = p.value(QStringLiteral("date")).toString();
        s.blobs.append(b);
        if (b.rarity == QLatin1String("mythic")) s.mythicSeen = true;
    } else if (t == QLatin1String("egg_retired")) {
        removeById(s.blobs, p.value(QStringLiteral("id")).toString());
    } else if (t == QLatin1String("decoration_bought")) {
        s.decorations.insert(p.value(QStringLiteral("decoration_id")).toString());
    } else if (t == QLatin1String("biome_bought")) {
        s.themesOwned.insert(p.value(QStringLiteral("biome_id")).toString());
    } else if (t == QLatin1String("focus_completed")) {
        s.focusTotal += 1;
        recordDeed(s, e.localDate);
    } else if (t == QLatin1String("egg_claimed")) {
        const QString id = p.value(QStringLiteral("id")).toString();
        if (!s.eggsClaimed.contains(id)) {
            s.eggsClaimed.insert(id);
            s.crumbs += p.value(QStringLiteral("crumbs")).toInt();
        }
    } else if (t == QLatin1String("migrated")) {
        s = fromJson(p);
    }
    // app_opened and unknown types: no-op.
}

// ---- serialisation (for the migration snapshot) ---------------------------------------------
static QJsonArray strSetToJson(const QSet<QString>& set)
{ QJsonArray a; for (const QString& v : set) a.append(v); return a; }
static QSet<QString> jsonToStrSet(const QJsonArray& a)
{ QSet<QString> s; for (const QJsonValue& v : a) s.insert(v.toString()); return s; }
static QJsonObject intMapToJson(const QMap<QString, int>& m)
{ QJsonObject o; for (auto it = m.begin(); it != m.end(); ++it) o.insert(it.key(), it.value()); return o; }
static QJsonObject strMapToJson(const QMap<QString, QString>& m)
{ QJsonObject o; for (auto it = m.begin(); it != m.end(); ++it) o.insert(it.key(), it.value()); return o; }

QJsonObject toJson(const ZooState& s)
{
    QJsonObject o;
    o.insert(QStringLiteral("crumbs"), s.crumbs);
    QJsonArray habits;
    for (const Habit& h : s.habits) {
        QJsonObject j; j.insert("id", h.id); j.insert("name", h.name); j.insert("target", h.target);
        j.insert("kind", h.kind);
        habits.append(j);
    }
    o.insert(QStringLiteral("habits"), habits);
    QJsonArray quests;
    for (const Quest& q : s.quests) {
        QJsonObject j; j.insert("id", q.id); j.insert("name", q.name); j.insert("due", q.due);
        quests.append(j);
    }
    o.insert(QStringLiteral("quests"), quests);
    QJsonArray blobs;
    for (const Blob& b : s.blobs) {
        QJsonObject j; j.insert("id", b.id); j.insert("seed", b.seed);
        j.insert("rarity", b.rarity); j.insert("date", b.date);
        blobs.append(j);
    }
    o.insert(QStringLiteral("blobs"), blobs);
    o.insert(QStringLiteral("decorations"), strSetToJson(s.decorations));
    o.insert(QStringLiteral("themesOwned"), strSetToJson(s.themesOwned));
    o.insert(QStringLiteral("eggsClaimed"), strSetToJson(s.eggsClaimed));
    o.insert(QStringLiteral("habitCount"), intMapToJson(s.habitCount));
    o.insert(QStringLiteral("habitLast"), strMapToJson(s.habitLast));
    o.insert(QStringLiteral("deedByDate"), intMapToJson(s.deedByDate));
    o.insert(QStringLiteral("slipByDate"), intMapToJson(s.slipByDate));
    o.insert(QStringLiteral("slipTotal"), s.slipTotal);
    o.insert(QStringLiteral("challengeStatus"), strMapToJson(s.challengeStatus));
    o.insert(QStringLiteral("habitLogTotal"), s.habitLogTotal);
    o.insert(QStringLiteral("questCompletedTotal"), s.questCompletedTotal);
    o.insert(QStringLiteral("focusTotal"), s.focusTotal);
    o.insert(QStringLiteral("deeds"), s.deeds);
    o.insert(QStringLiteral("streak"), s.streak);
    o.insert(QStringLiteral("lastActiveDate"), s.lastActiveDate);
    o.insert(QStringLiteral("mythicSeen"), s.mythicSeen);
    o.insert(QStringLiteral("nightOwl"), s.nightOwl);
    return o;
}

ZooState fromJson(const QJsonObject& o)
{
    ZooState s;
    s.crumbs = o.value(QStringLiteral("crumbs")).toInt();
    for (const QJsonValue& v : o.value(QStringLiteral("habits")).toArray()) {
        const QJsonObject j = v.toObject();
        Habit h; h.id = j.value("id").toString(); h.name = j.value("name").toString();
        h.target = qMax(1, j.value("target").toInt(1));
        h.kind = (j.value("kind").toString() == QLatin1String("bad")) ? QStringLiteral("bad") : QStringLiteral("good");
        s.habits.append(h);
    }
    for (const QJsonValue& v : o.value(QStringLiteral("quests")).toArray()) {
        const QJsonObject j = v.toObject();
        Quest q; q.id = j.value("id").toString(); q.name = j.value("name").toString();
        q.due = j.value("due").toString(); s.quests.append(q);
    }
    for (const QJsonValue& v : o.value(QStringLiteral("blobs")).toArray()) {
        const QJsonObject j = v.toObject();
        Blob b; b.id = j.value("id").toString(); b.seed = j.value("seed").toInt();
        b.rarity = j.value("rarity").toString(); b.date = j.value("date").toString(); s.blobs.append(b);
    }
    s.decorations = jsonToStrSet(o.value(QStringLiteral("decorations")).toArray());
    s.themesOwned = jsonToStrSet(o.value(QStringLiteral("themesOwned")).toArray());
    s.eggsClaimed = jsonToStrSet(o.value(QStringLiteral("eggsClaimed")).toArray());
    const QJsonObject hc = o.value(QStringLiteral("habitCount")).toObject();
    for (auto it = hc.begin(); it != hc.end(); ++it) s.habitCount.insert(it.key(), it.value().toInt());
    const QJsonObject hl = o.value(QStringLiteral("habitLast")).toObject();
    for (auto it = hl.begin(); it != hl.end(); ++it) s.habitLast.insert(it.key(), it.value().toString());
    const QJsonObject dd = o.value(QStringLiteral("deedByDate")).toObject();
    for (auto it = dd.begin(); it != dd.end(); ++it) s.deedByDate.insert(it.key(), it.value().toInt());
    const QJsonObject sd = o.value(QStringLiteral("slipByDate")).toObject();
    for (auto it = sd.begin(); it != sd.end(); ++it) s.slipByDate.insert(it.key(), it.value().toInt());
    s.slipTotal = o.value(QStringLiteral("slipTotal")).toInt();
    const QJsonObject cs = o.value(QStringLiteral("challengeStatus")).toObject();
    for (auto it = cs.begin(); it != cs.end(); ++it) s.challengeStatus.insert(it.key(), it.value().toString());
    s.habitLogTotal = o.value(QStringLiteral("habitLogTotal")).toInt();
    s.questCompletedTotal = o.value(QStringLiteral("questCompletedTotal")).toInt();
    s.focusTotal = o.value(QStringLiteral("focusTotal")).toInt();
    s.deeds = o.value(QStringLiteral("deeds")).toInt();
    s.streak = o.value(QStringLiteral("streak")).toInt();
    s.lastActiveDate = o.value(QStringLiteral("lastActiveDate")).toString();
    s.mythicSeen = o.value(QStringLiteral("mythicSeen")).toBool();
    s.nightOwl = o.value(QStringLiteral("nightOwl")).toBool();
    return s;
}

} // namespace zoo
