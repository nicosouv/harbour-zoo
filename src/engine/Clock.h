// The engine's one and only source of "now". Injectable so tests can pin time and assert exact,
// deterministic behaviour (streak/grace edge cases, odd-hour secrets). No other engine code may
// call wall-clock time directly.
#ifndef ZOO_CLOCK_H
#define ZOO_CLOCK_H

#include <QDateTime>
#include <QString>

namespace zoo {

class Clock {
public:
    virtual ~Clock() = default;

    // Current instant, UTC.
    virtual QDateTime nowUtc() const = 0;

    // Convenience derivations used across the engine. Local time drives streak/secret logic.
    QString isoUtc() const { return nowUtc().toString(Qt::ISODate); }
    QString localDate() const { return nowUtc().toLocalTime().toString(QStringLiteral("yyyy-MM-dd")); }
    int localHour() const { return nowUtc().toLocalTime().time().hour(); }
};

// Production clock: the real system time.
class SystemClock : public Clock {
public:
    QDateTime nowUtc() const override { return QDateTime::currentDateTimeUtc(); }
};

// Test clock: a fixed, settable instant.
class FixedClock : public Clock {
public:
    explicit FixedClock(const QDateTime& fixedUtc) : m_now(fixedUtc) {}
    QDateTime nowUtc() const override { return m_now; }
    void set(const QDateTime& utc) { m_now = utc; }
    void advanceSecs(qint64 s) { m_now = m_now.addSecs(s); }
private:
    QDateTime m_now;
};

} // namespace zoo

#endif // ZOO_CLOCK_H
