/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
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

Item {
    id: root
    clip: true

    property string message:       ""
    property real   fontSize:      Dims.l(40)
    property string fontStyleName: "Bold"
    property real   dimsPerSecond: 60
    property bool   scrolling:     true

    Label {
        id: scrollLabel
        x: root.width
        y: Math.round((root.height - contentHeight) / 2)
        text:           root.message.toUpperCase()
        font.pixelSize: root.fontSize
        font.styleName: root.fontStyleName
        color:          "#ffffff"
        verticalAlignment: Text.AlignVCenter
        onContentWidthChanged: root.restartScroll()
    }

    // Timer-driven scroll — advances x by real elapsed time each tick so
    // dimsPerSecond changes take effect immediately without restarting.
    // This is what gives the DJ-push feel: speed updates mid-scroll.
    Timer {
        id: scrollTimer
        interval: 16   // ~60fps
        repeat:   true
        running:  root.scrolling && scrollLabel.contentWidth > 0

        property real lastMs: 0

        onRunningChanged: {
            if (running) {
                lastMs = Date.now()
            } else {
                scrollLabel.x = root.width
                lastMs = 0
            }
        }

        onTriggered: {
            var now     = Date.now()
            var elapsed = lastMs > 0 ? now - lastMs : interval
            lastMs = now
            var advance = (root.dimsPerSecond * Dims.l(1) / 1000) * elapsed
            scrollLabel.x -= advance
            if (scrollLabel.x <= -scrollLabel.contentWidth)
                scrollLabel.x = root.width
        }
    }
}
