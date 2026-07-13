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
        h.cue = p.value(QStringLiteral("cue")).toString();
        h.replacement = p.value(QStringLiteral("replacement")).toString();
        const QString until = p.value(QStringLiteral("toleratedUntil")).toString();
        if (!until.isEmpty()) {
            h.toleratedUntil = until;
        } else if (p.value(QStringLiteral("tolerated")).toBool()) {
            // Simple opt-in: tolerate for two weeks from creation, then the app re-asks.
            const QDate cd = QDate::fromString(e.localDate, QStringLiteral("yyyy-MM-dd"));
            if (cd.isValid()) h.toleratedUntil = cd.addDays(14).toString(QStringLiteral("yyyy-MM-dd"));
        }
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
        s.habitLast[id] = d;
        // Bounded indulgence: while inside its tolerance window a bad habit is still counted for
        // you, but it does not tint the zoo's mood — no shame, just awareness. Once the window
        // passes, slips count again (a gentle, automatic re-ask). Dates compare as strings.
        QString until;
        for (const Habit& h : s.habits) if (h.id == id) { until = h.toleratedUntil; break; }
        const bool tolerated = !until.isEmpty() && d <= until;
        if (!tolerated) {
            s.slipByDate[d] = s.slipByDate.value(d, 0) + 1;
            s.slipTotal += 1;
        }
    } else if (t == QLatin1String("habit_tolerance_set")) {
        // Extend the tolerance window (a fresh date) or tighten it back to accountable ("" = none).
        const QString id = p.value(QStringLiteral("habit_id")).toString();
        const QString until = p.value(QStringLiteral("until")).toString();
        for (Habit& h : s.habits) if (h.id == id) { h.toleratedUntil = until; break; }
    } else if (t == QLatin1String("mood_logged")) {
        // A light emotional check-in (smiley 1..5). Latest of the day wins; purely a private read
        // that lets the app sense whether now is a push day or a be-gentle day.
        QString d = p.value(QStringLiteral("date")).toString();
        if (d.isEmpty()) d = e.localDate;
        const int v = p.value(QStringLiteral("valence")).toInt();
        if (v >= 1 && v <= 5) { s.moodByDate[d] = v; s.moodLogTotal += 1; }
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
        s.retiredTotal += 1;
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
        j.insert("cue", h.cue); j.insert("replacement", h.replacement);
        j.insert("toleratedUntil", h.toleratedUntil);
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
    o.insert(QStringLiteral("moodByDate"), intMapToJson(s.moodByDate));
    o.insert(QStringLiteral("moodLogTotal"), s.moodLogTotal);
    o.insert(QStringLiteral("habitLogTotal"), s.habitLogTotal);
    o.insert(QStringLiteral("questCompletedTotal"), s.questCompletedTotal);
    o.insert(QStringLiteral("focusTotal"), s.focusTotal);
    o.insert(QStringLiteral("retiredTotal"), s.retiredTotal);
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
        h.cue = j.value("cue").toString();
        h.replacement = j.value("replacement").toString();
        h.toleratedUntil = j.value("toleratedUntil").toString();
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
    const QJsonObject md = o.value(QStringLiteral("moodByDate")).toObject();
    for (auto it = md.begin(); it != md.end(); ++it) s.moodByDate.insert(it.key(), it.value().toInt());
    s.moodLogTotal = o.value(QStringLiteral("moodLogTotal")).toInt();
    s.habitLogTotal = o.value(QStringLiteral("habitLogTotal")).toInt();
    s.questCompletedTotal = o.value(QStringLiteral("questCompletedTotal")).toInt();
    s.focusTotal = o.value(QStringLiteral("focusTotal")).toInt();
    s.retiredTotal = o.value(QStringLiteral("retiredTotal")).toInt();
    s.deeds = o.value(QStringLiteral("deeds")).toInt();
    s.streak = o.value(QStringLiteral("streak")).toInt();
    s.lastActiveDate = o.value(QStringLiteral("lastActiveDate")).toString();
    s.mythicSeen = o.value(QStringLiteral("mythicSeen")).toBool();
    s.nightOwl = o.value(QStringLiteral("nightOwl")).toBool();
    return s;
}

} // namespace zoo
