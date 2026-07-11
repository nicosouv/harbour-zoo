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
    if (translator.load(QStringLiteral("harbour-zoo-") + locale, trDir)
        || translator.load(QStringLiteral("harbour-zoo-") + locale.left(2), trDir)) {
        app->installTranslator(&translator);
    }

    zoo::ZooController controller;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("Zoo"), &controller);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-zoo.qml")));
    view->show();

    return app->exec();
}
