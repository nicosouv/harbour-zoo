#include <QtQuick>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <sailfishapp.h>

#include "engine/ZooController.h"

int main(int argc, char* argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    zoo::ZooController controller;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("Zoo"), &controller);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-zoo.qml")));
    view->show();

    return app->exec();
}
