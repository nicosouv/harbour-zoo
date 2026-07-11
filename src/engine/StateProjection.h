// The pure projection: current state = fold of the event log through applyEvent(). Deterministic
// and unit-tested. toJson/fromJson serialise a whole state (used for the migration snapshot event).
#ifndef ZOO_STATEPROJECTION_H
#define ZOO_STATEPROJECTION_H

#include "ZooState.h"
#include "EventStore.h"
#include <QJsonObject>

namespace zoo {

// Fold one event into the state (in place). Pure w.r.t. its inputs — no I/O, no clock.
void applyEvent(ZooState& state, const Event& event);

QJsonObject toJson(const ZooState& state);
ZooState    fromJson(const QJsonObject& obj);

} // namespace zoo

#endif // ZOO_STATEPROJECTION_H
