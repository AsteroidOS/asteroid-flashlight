/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls

// Ring color selector. A thin, subtle circle outline around the collapsed
// trigger, drawn in the currently selected color: the selection shows
// itself, no names to read. Size this item to the full touch disc (90% of
// the screen circle, measured from real tap telemetry); the whole disc cycles the color so the change is
// discovered by accident, while the outer screen edge stays free for edge
// gestures. Instantiate BEFORE the feature trigger in code order: the
// trigger and the mode cycler stack above and win their own taps.
Item {
    id: root

    // Diameter of the collapsed trigger the ring wraps.
    property real circleDiameter: 0
    property real ringWidth: Dims.l(1.2)
    // Divider between the circle edge and the ring. Tunable.
    property real gap: Dims.l(6)
    readonly property real outerRadius: circleDiameter / 2 + gap + ringWidth

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            var dx = mouse.x - width / 2
            var dy = mouse.y - height / 2
            // Beyond the disc: not ours, the screen edge stays free for
            // edge gestures.
            if (Math.sqrt(dx * dx + dy * dy) > width / 2)
                mouse.accepted = false
        }
        onClicked: {
            app.colorIndex = (app.colorIndex + 1) % app.colorValues.length
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width:  root.circleDiameter + 2 * (root.gap + root.ringWidth)
        height: width
        radius: width / 2
        color: "transparent"
        opacity: 0.7
        border.color: app.colorValues[app.colorIndex]
        border.width: root.ringWidth
    }

    // A color change emits a single subtle ripple: a thin outline born on
    // the ring, expanding and fading. Relaxed and barely noticeable by
    // design; scale-based so it costs no relayout.
    Rectangle {
        id: ripple
        anchors.centerIn: parent
        width:  root.circleDiameter + 2 * (root.gap + root.ringWidth)
        height: width
        radius: width / 2
        color: "transparent"
        border.color: app.colorValues[app.colorIndex]
        border.width: root.ringWidth
        opacity: 0

        ParallelAnimation {
            id: rippleAnim
            NumberAnimation { target: ripple; property: "scale";   from: 1; to: 1.35; duration: 650; easing.type: Easing.OutQuad }
            SequentialAnimation {
                NumberAnimation { target: ripple; property: "opacity"; from: 0; to: 0.35; duration: 120 }
                NumberAnimation { target: ripple; property: "opacity"; to: 0; duration: 530; easing.type: Easing.OutQuad }
            }
        }
    }

    Connections {
        target: app
        function onColorIndexChanged() { rippleAnim.restart() }
    }
}
