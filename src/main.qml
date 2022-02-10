/*
 * Copyright (C) 2019 Florent Revest <revestflo@gmail.com>
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
import Nemo.KeepAlive 1.1

Application {
    centerColor: "#00A698"
    outerColor: "#000C07"

    Rectangle {
        id: whiteOverlay
        color: "#fff"
        anchors.fill: parent
        OpacityAnimator {
            id: onOffAnimation
            target: whiteOverlay
            to: 1
            duration: 100
        }
    }

    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Dims.l(20)
        height: width
        name:  "ios-bulb"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (onOffAnimation.to == 1) {
                onOffAnimation.from = 1
                onOffAnimation.to = 0
                onOffAnimation.start()
            } else {
                onOffAnimation.from = 0
                onOffAnimation.to = 1
                onOffAnimation.start()
            }
        }
    }
    Component.onCompleted: DisplayBlanking.preventBlanking = true
}
