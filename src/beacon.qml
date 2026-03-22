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
import org.asteroid.utils 1.0

Item {
    id: root
    property bool pageActive: false
    property bool beaconOn:   false

    // ── Mode ─────────────────────────────────────────────────────────────────
    property string selectedMode: "Pulse"
    property bool   isPulse:      selectedMode === "Pulse"
    // ────────────────────────────────────────────────────────────────────────

    // ── Speed ─────────────────────────────────────────────────────────────────
    property real speedMultiplier: 1.0
    // ────────────────────────────────────────────────────────────────────────

    // ── Color ─────────────────────────────────────────────────────────────────
    property int   hueValue:    0
    property color beaconColor: hueValue === 0
    ? "#ffffff"
    : Qt.hsla(hueValue / 360, 1.0, 0.5, 1.0)
    // ────────────────────────────────────────────────────────────────────────

    // ── Signal level (0.0–1.0) ───────────────────────────────────────────────
    // Single property driven by both pulse animation and morse timer.
    // Always live when pageActive — beaconOn only changes the opacity floor.
    // Idle:   opacity = 0.4 + signalLevel * 0.6   (floor 0.4 → peak 1.0)
    // Active: opacity = signalLevel                (floor 0.0 → peak 1.0)
    property real signalLevel: 1.0
    // ────────────────────────────────────────────────────────────────────────

    // ── Sequences ────────────────────────────────────────────────────────────
    property var sequences: ({
        "Pulse":     [2000, 1000],
        "Emergency": [400, 150, 400, 1200],
        "SOS": [
            200, 200, 200, 200, 200, 600,
            600, 200, 600, 200, 600, 600,
            200, 200, 200, 200, 200, 1400
        ],
        "CQD": [
            600, 200, 200, 200, 600, 200, 200, 600,
            600, 200, 600, 200, 200, 200, 600, 600,
            600, 200, 200, 200, 200, 1400
        ],
        "XXX": [
            600, 200, 200, 200, 200, 200, 600, 600,
            600, 200, 200, 200, 200, 200, 600, 600,
            600, 200, 200, 200, 200, 200, 600, 1400
        ],
        "MAYDAY": [
            600, 200, 600, 600,
            200, 200, 600, 600,
            600, 200, 200, 200, 600, 200, 600, 600,
            600, 200, 200, 200, 200, 600,
            200, 200, 600, 600,
            600, 200, 200, 200, 600, 200, 600, 1400
        ]
    })

    property int morseIndex: 0
    property var currentSeq: sequences[selectedMode]
    // ────────────────────────────────────────────────────────────────────────

    anchors.fill: parent
    clip: true

    //% "Beacon"
    PageHeader {
        text: qsTrId("id-beacon")
        visible: !beaconOn
    }

    Rectangle {
        id: beaconBack
        anchors.centerIn: parent
        width:   Dims.w(40)
        height:  Dims.w(40)
        radius:  width / 2
        color:   "#66444444"
        visible: !beaconOn
    }

    // Solid black backdrop so the flash fades to black not the flatmesh
    Rectangle {
        anchors.centerIn: parent
        width:   beaconRect.width
        height:  beaconRect.height
        radius:  width / 2
        color:   beaconOn ? "#000000" : "#88222222"
    }

    // ── Mode cycler — above trigger ──────────────────────────────────────────
    // modeKeys are English strings used as sequences lookup keys — never translated.
    // modeLabels are the translated display strings shown in the ValueCycler.
    property var modeKeys: ["Pulse", "Emergency", "SOS", "CQD", "XXX", "MAYDAY"]
    property var modeLabels: [
        //% "Pulse"
        qsTrId("id-beacon-pulse"),
        //% "Emergency"
        qsTrId("id-cat-emergency"),
        "SOS", "CQD", "XXX", "MAYDAY"
    ]

    ValueCycler {
        anchors {
            bottom:       beaconRect.top
            bottomMargin: Dims.l(6)
            left:         parent.left
            right:        parent.right
        }
        height: Dims.l(16)
        visible: !beaconOn
        valueArray:   modeLabels
        currentValue: modeLabels[modeKeys.indexOf(selectedMode)]
        onValueChanged: {
            selectedMode    = modeKeys[modeLabels.indexOf(value)]
            currentSeq      = sequences[selectedMode]
            speedMultiplier = 1.0
            restartSignal()
        }
    }

    // ── Beacon rect ─────────────────────────────────────────────────────────
    Rectangle {
        id: beaconRect
        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight / 2

        // Color is always beaconColor — pure binding, never imperatively broken.
        // beaconOn only changes the opacity floor via signalLevel mapping.
        color:   beaconColor
        opacity: signalLevel
        width:   beaconOn ? root.width  : Dims.w(26)
        height:  beaconOn ? root.height : Dims.w(26)
        radius:  beaconOn ? (DeviceSpecs.hasRoundScreen ? width / 2 : 0) : width / 2

        MouseArea {
            anchors.fill: parent
            property real pressX: 0
            property real pressY: 0
            onPressed:  { pressX = mouse.x; pressY = mouse.y }
            onReleased: {
                if (Math.abs(mouse.x - pressX) < Dims.l(3) &&
                    Math.abs(mouse.y - pressY) < Dims.l(3))
                    beaconOn = !beaconOn
            }
        }

        Behavior on width  { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }
    }

    // Barely visible dark icon — same "not a bug" subtlety as the flashlight bulb.
    // Qt.rgba(0,0,0,0.2) works on any beaconColor including white.
    Icon {
        anchors.centerIn: beaconRect
        name: "ios-radio-outline"
        width:  beaconRect.width  * 0.95
        height: beaconRect.height * 0.95
        color:  beaconOn ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(0, 0, 0, 0.7)
    }

    // ── Hue selector — below trigger ─────────────────────────────────────────
    IntSelector {
        anchors {
            top:       beaconRect.bottom
            topMargin: Dims.l(9)
            left:      parent.left
            right:     parent.right
        }
        height: Dims.l(18)
        visible: !beaconOn
        min:      0
        max:      360
        stepSize: 10
        value:    hueValue
        unitMarker: "°"
        onValueChanged: hueValue = value
    }
    // ────────────────────────────────────────────────────────────────────────

    // ── Pulse animation — always live when pageActive ─────────────────────────
    // Targets signalLevel so the opacity mapping handles both idle and active.
    // Restart on speed change to pick up new durations immediately.
    SequentialAnimation {
        id: pulseAnim
        running: isPulse && pageActive
        loops:   Animation.Infinite
        onRunningChanged: if (!running) signalLevel = 1.0

        NumberAnimation { target: root; property: "signalLevel"; to: 1.0; duration: Math.round(500  / speedMultiplier); easing.type: Easing.InOutQuad }
        PauseAnimation  { duration: Math.round(200  / speedMultiplier) }
        NumberAnimation { target: root; property: "signalLevel"; to: 0.0; duration: Math.round(1300 / speedMultiplier); easing.type: Easing.InOutQuad }
        PauseAnimation  { duration: Math.round(1000 / speedMultiplier) }
    }

    onSpeedMultiplierChanged: {
        if (isPulse && pageActive) pulseAnim.restart()
            else if (!isPulse && pageActive) restartSignal()
    }
    // ────────────────────────────────────────────────────────────────────────

    // ── Morse timer — always live when pageActive and not Pulse ──────────────
    Timer {
        id: signalTimer
        repeat:  false
        running: false
        onTriggered: {
            morseIndex++
            if (morseIndex >= currentSeq.length) morseIndex = 0
                // Even = ON (1.0), odd = OFF (0.0). Opacity floor handles idle vs active.
                signalLevel = (morseIndex % 2 === 0) ? 1.0 : 0.0
                if (pageActive && !isPulse) {
                    interval = Math.round(currentSeq[morseIndex] / speedMultiplier)
                    restart()
                }
        }
    }

    onPageActiveChanged: {
        if (pageActive) restartSignal()
            else
                signalTimer.stop()
    }

    function restartSignal() {
        if (isPulse) {
            pulseAnim.restart()
        } else {
            signalTimer.stop()
            morseIndex  = 0
            signalLevel = 1.0
            signalTimer.interval = Math.round(currentSeq[0] / speedMultiplier)
            signalTimer.start()
        }
    }
    // ────────────────────────────────────────────────────────────────────────

    // ── Drag speed overlay — active while beacon is running ──────────────────
    MouseArea {
        anchors.fill: parent
        enabled: beaconOn && pageActive

        property real pressX:      0
        property real pressY:      0
        property real pressSpeed:  0
        property bool tracking:    false
        property bool axisDecided: false
        property real threshold:   Dims.l(3)

        onPressed: {
            pressX      = mouse.x
            pressY      = mouse.y
            pressSpeed  = speedMultiplier
            tracking    = false
            axisDecided = false
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
            var delta = mouse.x - pressX
            speedMultiplier = Math.max(0.25, Math.min(4.0, pressSpeed - delta / (Dims.l(1) * 20)))
            speedLabel.opacity = 1
        }

        onReleased: {
            if (!tracking) beaconOn = false
                tracking        = false
                axisDecided     = false
                preventStealing = false
                speedHideTimer.restart()
        }

        onCanceled: {
            tracking        = false
            axisDecided     = false
            preventStealing = false
            speedHideTimer.restart()
        }
    }

    Timer {
        id: speedHideTimer
        interval: 800
        repeat:   false
        onTriggered: speedLabel.opacity = 0
    }

    Label {
        id: speedLabel
        anchors {
            verticalCenter:   parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        visible: beaconOn
        enabled: false
        text: "\u00D7" + speedMultiplier.toFixed(2)
        font.pixelSize: Dims.l(14)
        color: "#00A698"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    // ────────────────────────────────────────────────────────────────────────
}
