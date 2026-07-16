#include <QtQuick>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <QTranslator>
#include <QLocale>
#include <QSettings>
#include <sailfishapp.h>

#include "engine/AppId.h"
#include "engine/ZooController.h"

int main(int argc, char* argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    // Language: an explicit choice in Settings overrides the system locale. (Qt 5.6 can't
    // retranslate live, so a change takes effect on the next launch.)
    QSettings settings(QLatin1String(zoo::AppId::kOrganization),
                       QLatin1String(zoo::AppId::kApplication));
    const QString chosen = settings.value(QStringLiteral("language")).toString();
    const QString locale = chosen.isEmpty() ? QLocale::system().name() : chosen;

    QTranslator translator;
    const QString trDir = SailfishApp::pathTo(QStringLiteral("translations")).toLocalFile();
    bool loaded = translator.load(QStringLiteral("harbour-zoo-") + locale, trDir)
               || translator.load(QStringLiteral("harbour-zoo-") + locale.left(2), trDir);
    if (!loaded && locale.startsWith(QStringLiteral("zh"), Qt::CaseInsensitive)) {
        // System Chinese locales come in several shapes (zh_CN, zh_Hans, zh_SG, zh_TW, zh_HK,
        // zh_Hant_TW...); neither exact nor two-letter match above catches those, so fall back to
        // simplified/traditional by looking for a Hant/TW/HK/MO marker.
        const bool traditional = locale.contains(QStringLiteral("TW"), Qt::CaseInsensitive)
                               || locale.contains(QStringLiteral("HK"), Qt::CaseInsensitive)
                               || locale.contains(QStringLiteral("MO"), Qt::CaseInsensitive)
                               || locale.contains(QStringLiteral("Hant"), Qt::CaseInsensitive);
        loaded = translator.load(traditional ? QStringLiteral("harbour-zoo-zh_TW")
                                              : QStringLiteral("harbour-zoo-zh_CN"), trDir);
    }
    if (loaded) app->installTranslator(&translator);

    zoo::ZooController controller;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("Zoo"), &controller);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-zoo.qml")));
    view->show();

    return app->exec();
}
