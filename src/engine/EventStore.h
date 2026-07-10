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

private:
    bool exec(const QString& sql);

    QString m_connectionName;
    bool    m_open = false;
};

} // namespace zoo

#endif // ZOO_EVENTSTORE_H
