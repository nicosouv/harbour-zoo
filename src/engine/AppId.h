// Single place for all name / app-id / service / storage constants, so the app can be renamed
// (Zoo → whatever) in exactly one file. Nothing else in the codebase should hardcode these.
#ifndef ZOO_APPID_H
#define ZOO_APPID_H

namespace zoo {
namespace AppId {

// Reverse-DNS-ish organisation + app identifiers (used by QSettings, paths, D-Bus if ever needed).
static const char* const kOrganization = "harbour-zoo";
static const char* const kApplication  = "harbour-zoo";

// Human-facing display name (subtitle lives in QML copy / translations).
static const char* const kDisplayName  = "Zoo";

// On-disk database file name (stored under the app's local data dir).
static const char* const kDatabaseFile = "zoo.sqlite";

// SQLite schema version. Bump when the schema changes; migrations key off this.
static const int kSchemaVersion = 1;

// The soft currencies (renameable here only). See docs/creative-direction.md.
static const char* const kCurrencyCrumbs = "crumbs";
static const char* const kCurrencyRenown = "renown";

} // namespace AppId
} // namespace zoo

#endif // ZOO_APPID_H
