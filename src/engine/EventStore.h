// The single source of truth: an append-only event log over SQLite. Never UPDATE or DELETE rows
// in `events`. All current state is a projection of this log (see StateProjection, to come), so
// the whole engine is reproducible and testable. Also owns install_meta (the per-install salt
// that seeds every deterministic roll) and the specimen_instances table.
#ifndef ZOO_EVENTSTORE_H
#define ZOO_EVENTSTORE_H

#include <QString>
#include <QVector>
#include <QtGlobal>

namespace zoo {

struct Event {
    qint64  seq = 0;         // monotonic primary key (append order)
    QString type;            // event type (see docs/zoo-spec.md §4.2 + utility-spine/zoo-meta)
    QString tsUtc;           // ISO-8601 UTC instant
    QString localDate;       // YYYY-MM-DD device-local (streak logic)
    int     localHour = 0;   // 0..23 device-local (odd-hour secrets)
    QString payload;         // event-specific JSON
};

class EventStore {
public:
    explicit EventStore(const QString& connectionName = QStringLiteral("zoo_main"));
    ~EventStore();

    // Open the database at `path` (use ":memory:" for tests). Returns false on failure.
    bool open(const QString& path);
    void close();
    bool isOpen() const;

    // Create tables if absent and ensure the single install_meta row exists. If it's a fresh
    // install, `saltIfNew` becomes the permanent install salt (production passes a random value;
    // tests pass a fixed one). Idempotent — safe to call on every launch.
    bool bootstrap(quint64 saltIfNew);

    // The permanent per-install salt that seeds all deterministic RNG. 0 if not bootstrapped.
    quint64 installSalt() const;

    // Append one event. Returns the new seq, or -1 on failure.
    qint64 appendEvent(const QString& type, const QString& tsUtc,
                       const QString& localDate, int localHour, const QString& payload);

    // All events in append order. This is what a projection folds over.
    QVector<Event> events() const;

    // Cheap count of the log.
    int eventCount() const;

    // Highest seq in the log (0 if empty).
    qint64 maxSeq() const;

    // Projection snapshot (bounds the log): store the folded state as of a seq, then prune the
    // events below it. On launch, load the snapshot and replay only events after `asOfSeq`.
    bool saveSnapshot(qint64 asOfSeq, const QString& stateJson);
    bool loadSnapshot(qint64& asOfSeq, QString& stateJson) const;
    bool pruneEventsBefore(qint64 seq);   // DELETE rows with seq < seq (compensated by snapshot)

    // Wipe all log data (events + snapshot + specimen rows). Keeps install_meta. For a full reset.
    bool clearAll();

private:
    bool exec(const QString& sql);

    QString m_connectionName;
    bool    m_open = false;
};

} // namespace zoo

#endif // ZOO_EVENTSTORE_H
