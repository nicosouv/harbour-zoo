// Deterministic, seedable PRNG. ALL randomness in the engine goes through this — never rand()/
// QRandomGenerator/time(). Seeds are always derived (install_salt mixed with a counter or date
// ordinal), so every roll is reproducible and unit-testable. splitmix64 is the generator; it is
// fast, has good statistical quality, and produces the same stream everywhere.
#ifndef ZOO_RNG_H
#define ZOO_RNG_H

#include <QtGlobal>

namespace zoo {

class Rng {
public:
    explicit Rng(quint64 seed) : m_state(seed) {}

    // Next raw 64-bit value (splitmix64).
    quint64 next();

    // Uniform double in [0, 1).
    double nextDouble();

    // Uniform integer in [0, bound). Returns 0 if bound == 0.
    quint32 nextBounded(quint32 bound);

    // Derive a fresh, well-mixed seed from two inputs (e.g. install_salt + date ordinal). Static
    // and pure: the cornerstone of "same specimen forever" and reproducible daily challenges.
    static quint64 mix(quint64 a, quint64 b);

private:
    quint64 m_state;
};

} // namespace zoo

#endif // ZOO_RNG_H
