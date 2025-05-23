/*
 * Copyright (C) 2022 Timo Könnecke <github.com/eLtMosen>
 *               2019 Florent Revest <revestflo@gmail.com>
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
import org.nemomobile.systemsettings 1.0
import Nemo.KeepAlive 1.1

Application {
    centerColor: "#00A698"
    outerColor: "#000C07"
    property int startBrightness: -1

    DisplaySettings {
        id: displaySettings
        onBrightnessChanged: {
            if (startBrightness != -1) {
                return
            }

            startBrightness = brightness
            displaySettings.brightness = displaySettings.maximumBrightness
        }
    }

    Rectangle {
        id: flashCircle

        property bool flashOn: true

        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight/2
        color: flashOn ? "#ffffffff" : "#66444444"
        width: flashOn ? Dims.w(100) : Dims.w(45)
        height: flashOn ? Dims.h(100) : Dims.h(45)
        radius: DeviceSpecs.hasRoundScreen ? width : flashOn ? 0 : width

        Icon {
            anchors.centerIn: flashCircle
            width: flashCircle.width * .7
            height: width
            color: flashCircle.flashOn ? "#F0F0F0" : "#FFF"
            name:  flashCircle.flashOn ? "ios-bulb-outline" : "ios-bulb"
        }

        MouseArea {
            anchors.fill: flashCircle
            onClicked: {
                flashCircle.flashOn = !flashCircle.flashOn
                displaySettings.brightness = flashCircle.flashOn ? displaySettings.maximumBrightness : startBrightness
            }
        }

        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.InCurve } }
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.InCurve } }
        Behavior on radius { NumberAnimation { duration: 100; easing.type: Easing.OutQuint } }
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InCurve } }
    }

    Component.onCompleted: DisplayBlanking.preventBlanking = true
    Component.onDestruction: displaySettings.brightness = startBrightness
}
