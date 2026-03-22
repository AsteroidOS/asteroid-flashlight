/*
 * Copyright (C) 2025 - moWerk
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

/*!
    \qmltype ValueCycler
    \brief A minimal cycler showing only the current value, centered.

    Unlike OptionCycler there is no title label — just the value itself.
    Tap anywhere to advance to the next item. Wraps at end of array.
*/
Item {
    id: root

    property var    valueArray:   []
    property string currentValue: valueArray.length > 0 ? valueArray[0] : ""

    signal valueChanged(string value)

    Label {
        anchors.centerIn: parent
        text: currentValue
        font.pixelSize: Dims.l(8)
        horizontalAlignment: Text.AlignHCenter
    }

    HighlightBar {
        anchors.fill: parent
        onClicked: {
            if (valueArray.length === 0) return
            var i    = valueArray.indexOf(currentValue)
            var next = (i + 1) % valueArray.length
            valueChanged(valueArray[next])
        }
    }
}
