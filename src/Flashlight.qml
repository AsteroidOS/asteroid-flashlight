/*
 * SPDX-FileCopyrightText: 2022 Timo Könnecke <github.com/eLtMosen>
 * SPDX-FileCopyrightText: 2019 Florent Revest <revestflo@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    // Set by main.qml via Qt.binding after load
    property bool pageActive: false
    // Relayed to app.flashlightOn so blanking, PageDot and swiping react
    property bool flashOn: true

    // Collapsed trigger and ring diameter, 0.4 of the centered Math.min
    // square so every screen shape gets identical proportions.
    property real circleSize: Math.min(width, height - DeviceSpecs.flatTireHeight) * 0.4

    anchors.fill: parent

    PageHeader {
        //% "Flashlight"
        text: qsTrId("id-flashlight")
        visible: !flashOn
    }

    Rectangle {
        id: flashlightCircle

        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight / 2
        color: flashOn ? "#ffffffff" : "#66444444"
        width: flashOn ? Dims.w(100) : circleSize
        height: flashOn ? Dims.h(100) : circleSize
        radius: DeviceSpecs.hasRoundScreen ? width : flashOn ? 0 : width

        Icon {
            anchors.centerIn: parent
            width: flashlightCircle.width * 0.7
            height: width
            color: flashOn ? "#F2F2F2" : "#FFF"
            name:  flashOn ? "ios-bulb-outline" : "ios-bulb"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                flashOn = !flashOn
                if (app.displaySettings)
                    app.displaySettings.brightness = flashOn
                        ? app.displaySettings.maximumBrightness
                        : app.startBrightness
            }
        }

        Behavior on width  { NumberAnimation { duration: 100; easing.type: Easing.InCurve } }
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.InCurve } }
        Behavior on radius { NumberAnimation { duration: 100; easing.type: Easing.OutQuint } }
        Behavior on color  { ColorAnimation  { duration: 150; easing.type: Easing.InCurve } }
    }

}
