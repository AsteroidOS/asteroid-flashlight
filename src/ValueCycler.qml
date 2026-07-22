/*
 * SPDX-FileCopyrightText: 2025 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

/*!
    \qmltype ValueCycler
    \brief A minimal cycler showing only the current value, centered.

    Unlike OptionCycler there is no title label, just the value itself.
    Tap anywhere to advance to the next item. Wraps at end of array.
*/
Item {
    id: root

    property var    valueArray:   []
    property string currentValue: valueArray.length > 0 ? valueArray[0] : ""

    signal valueChanged(string value)

    // Press highlight extends past the label by exactly its corner radius
    // per side, so the rounded ends lie fully outside the text.
    Rectangle {
        anchors.centerIn: label
        width:  label.width + 2 * radius
        height: label.height + Dims.l(2)
        radius: Dims.l(5.5)
        color:  tapArea.containsPress ? "#33ffffff" : "#00ffffff"
        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    Label {
        id: label
        anchors.centerIn: parent
        text: currentValue
        font.pixelSize: Dims.l(8)
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: tapArea
        anchors.fill: parent
        onClicked: {
            if (valueArray.length === 0) return
            var i    = valueArray.indexOf(currentValue)
            var next = (i + 1) % valueArray.length
            valueChanged(valueArray[next])
        }
    }
}
