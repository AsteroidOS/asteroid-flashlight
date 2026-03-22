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
    property bool pageActive: false
    property bool strobeOn:   false
    property int  hz:         10

    anchors.fill: parent
    clip: true

    //% "Strobe"
    PageHeader {
        text: qsTrId("id-strobe")
        visible: !strobeOn
    }

    Rectangle {
        id: strobeBack
        anchors.centerIn: parent
        width:   Dims.w(40)
        height:  Dims.w(40)
        radius:  width / 2
        color:   "#66444444"
        visible: !beaconOn
    }

    // ── Flash surface ────────────────────────────────────────────────────────
    // Single rect that expands from button circle to full screen on activation.
    // Color is flipped by strobeTimer while active.
    Rectangle {
        id: strobeRect
        anchors.centerIn: parent
        color: "#000000"
        width:  strobeOn ? root.width  : Dims.w(26)
        height: strobeOn ? root.height : Dims.w(26)
        radius:  strobeOn ? (DeviceSpecs.hasRoundScreen ? width / 2 : 0) : width / 2
        clip: true

        Icon {
            id: strobeIcon
            anchors.centerIn: parent
            visible: !strobeOn
            name: "ios-flash-outline"
            width:  parent.width  * 0.95
            height: parent.height * 0.95
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            property real pressX: 0
            property real pressY: 0
            onPressed:  { pressX = mouse.x; pressY = mouse.y }
            onReleased: {
                if (Math.abs(mouse.x - pressX) < Dims.l(3) &&
                    Math.abs(mouse.y - pressY) < Dims.l(3))
                    strobeOn = !strobeOn
            }
        }

        Behavior on width  { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }
    }

    Timer {
        id: strobeTimer
        property bool flashPhase: false
        // Two ticks per cycle: half-period per tick
        interval: Math.max(20, Math.round(500 / hz))
        running:  pageActive
        repeat:   true
        onTriggered: {
            flashPhase = !flashPhase
            strobeOn
            ? strobeRect.color = flashPhase ? "#ffffff" : "#000000"
            : strobeIcon.color = flashPhase ? "#000000" : "#ffffff"
        }
    }

    onStrobeOnChanged: {
        if (!strobeOn) {
            strobeTimer.flashPhase = false
            strobeRect.color = "#000000"
        }
    }
    // ────────────────────────────────────────────────────────────────────────

    // RPM readout — above trigger circle, hidden while strobing
    Label {
        anchors {
            bottom:       strobeRect.top
            bottomMargin: Dims.l(8)
            horizontalCenter: parent.horizontalCenter
        }
        visible: !strobeOn
        text: Math.round(hz * 60) + " RPM"
        font.pixelSize: Dims.l(8)
    }

    // IntSelector for Hz — below trigger circle, pushed off screen when active.
    // The IntSelector's internal dragArea already handles horizontal scrubbing
    // with axis detection and preventStealing, so no extra overlay needed.
    IntSelector {
        anchors {
            top:       strobeRect.bottom
            topMargin: Dims.l(9)
            left:      parent.left
            right:     parent.right
        }
        height: Dims.l(18)
        min:      1
        max:      25
        stepSize: 1
        value:    hz
        unitMarker: " Hz"
        visible:  !strobeOn
        onValueChanged: hz = value
    }

    // ── Centered Hz feedback label ───────────────────────────────────────────
    // Declared BEFORE dragArea so dragArea is painted on top and receives
    // events first. Label fades in on drag, out 800ms after release.
    Label {
        id: hzFeedbackLabel
        anchors.centerIn: parent
        text: hz + " Hz"
        font.pixelSize: Dims.l(20)
        font.styleName: "Bold"
        color: "#00A698"
        opacity: 0
        // enabled: false ensures the label never intercepts taps even at opacity > 0
        enabled: false
        visible: strobeOn
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Timer {
        id: hzHideTimer
        interval: 800
        repeat:   false
        onTriggered: hzFeedbackLabel.opacity = 0
    }

    // ── Full-screen drag scrubber overlay ────────────────────────────────────
    // Only active while strobe is running, so it never blocks ListView swipes.
    // A plain tap (no horizontal drag detected) sets strobeOn = false.
    // Threshold increased to Dims.l(3) matching QuickPanelToggle pattern.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        propagateComposedEvents: true
        enabled: strobeOn && pageActive

        property bool tracking:    false
        property bool axisDecided: false
        property real pressX:      0
        property real pressY:      0
        property int  pressHz:     0
        property real threshold:   Dims.l(3)

        onPressed: {
            pressX      = mouse.x
            pressY      = mouse.y
            pressHz     = hz
            axisDecided = false
            tracking    = false
        }

        onPositionChanged: {
            if (axisDecided) {
                if (!tracking) return
            } else {
                var dx = Math.abs(mouse.x - pressX)
                var dy = Math.abs(mouse.y - pressY)
                if (dx < threshold && dy < threshold) return
                axisDecided = true
                if (dx >= dy) {
                    tracking        = true
                    preventStealing = true
                } else {
                    mouse.accepted = false
                    return
                }
            }
            var delta = Math.round((mouse.x - pressX) / Dims.l(8))
            hz = Math.max(1, Math.min(25, pressHz + delta))
            hzFeedbackLabel.opacity = 1
        }

        onReleased: {
            if (!tracking && strobeOn) strobeOn = false
            tracking        = false
            axisDecided     = false
            preventStealing = false
            hzHideTimer.restart()
        }

        onCanceled: {
            tracking        = false
            axisDecided     = false
            preventStealing = false
            hzHideTimer.restart()
        }
    }
    // ────────────────────────────────────────────────────────────────────────
}
