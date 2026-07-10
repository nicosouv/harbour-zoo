TARGET = harbour-zoo

CONFIG += sailfishapp
CONFIG += c++17

# Version is injected by the spec at build time (%qmake5 VERSION=%{version}).
isEmpty(VERSION) {
    VERSION = 0.1.0
}
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

SOURCES += src/main.cpp \
    src/engine/Rng.cpp \
    src/engine/EventStore.cpp \
    src/engine/ZooController.cpp

HEADERS += src/engine/AppId.h \
    src/engine/Clock.h \
    src/engine/Rng.h \
    src/engine/EventStore.h \
    src/engine/ZooController.h

QT += sql

DISTFILES += qml/harbour-zoo.qml \
    qml/cover/CoverPage.qml \
    qml/pages/TodayPage.qml \
    qml/pages/SpecimenPage.qml \
    qml/pages/SettingsPage.qml \
    qml/specimens/Specimen.qml \
    qml/specimens/BlobSpecimen.qml \
    rpm/harbour-zoo.spec \
    harbour-zoo.desktop

# Static content (challenges, specimen catalog, flavor pools) shipped read-only with the app.
data.files = data
data.path = /usr/share/$${TARGET}
INSTALLS += data

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-zoo-en.ts \
                translations/harbour-zoo-fr.ts \
                translations/harbour-zoo-de.ts \
                translations/harbour-zoo-it.ts \
                translations/harbour-zoo-es.ts \
                translations/harbour-zoo-fi.ts
