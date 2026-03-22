/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2019 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

Item {
    // Set by main.qml via Qt.binding after load
    property bool pageActive: false
    // Relayed to app.flashlightOn so the PageDot and ListView.interactive react
    property bool flashOn: true

    anchors.fill: parent

    //% "Flashlight"
    PageHeader {
        text: qsTrId("id-flashlight")
        visible: !flashOn
    }

    Rectangle {
        id: flashlightCircle

        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight / 2
        color: flashOn ? "#ffffffff" : "#66444444"
        width: flashOn ? Dims.w(100) : Dims.w(40)
        height: flashOn ? Dims.h(100) : Dims.h(40)
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
