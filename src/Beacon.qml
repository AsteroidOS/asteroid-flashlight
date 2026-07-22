/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Ngf

Item {
    id: root
    property bool pageActive: false
    property bool beaconOn:   false

    // Mode
    property string selectedMode: "Pulse"
    property bool   isPulse:      selectedMode === "Pulse"

    // Speed
    property real speedMultiplier: 1.0

    // Color, app-level shared state keeps torch and beacon in sync
    property color beaconColor: app.colorValues[app.colorIndex]

    // Signal level (0.0–1.0)
    // Single property driven by both pulse animation and morse timer.
    // Always live when pageActive, the collapsed circle previews the
    // selected pattern calmly via the opacity floor:
    // Idle:   opacity = 0.4 + signalLevel * 0.6   (floor 0.4 → peak 1.0)
    // Active: opacity = signalLevel                (floor 0.0 → peak 1.0)
    property real signalLevel: 1.0

    // Signal patterns: each array is alternating on/off durations in
    // milliseconds, looped (on, off, on, off, ...).
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

    anchors.fill: parent
    clip: true

    PageHeader {
        //% "Beacon"
        text: qsTrId("id-beacon")
        visible: !beaconOn
    }

    // Square guard: all page geometry lives in a centered Math.min square
    // (the watchface square-guard pattern), so square, round and beluga's
    // taller-than-wide screen all get identical proportions. The cyclers
    // are full bands between the collapsed circle's edge and the
    // header/dots insets, their labels center in the band, which makes
    // the margins to the circle and to the header/dots equal by
    // construction. Static geometry: nothing here follows the animating
    // beacon, so the cyclers never move.
    Item {
        id: squareGuard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight / 2
        width:  Math.min(parent.width, parent.height - DeviceSpecs.flatTireHeight)
        height: width

        property real circleSize:  width * 0.4
        property real bottomInset: Dims.l(8)   // page-dots zone
    }

    // Solid black backdrop so the fullscreen flash fades to black, not to
    // the flatmesh. Collapsed there is no backdrop: the trigger itself is
    // the standard translucent off-state circle.
    Rectangle {
        anchors.centerIn: beaconRect
        width:   beaconRect.width
        height:  beaconRect.height
        radius:  beaconRect.radius
        color:   "#000000"
        visible: beaconOn
    }

    // Mode cycler, above trigger
    // modeKeys are English strings used as sequences lookup keys, never translated.
    // modeLabels are the translated display strings shown in the ValueCycler.
    property var modeKeys: ["Pulse", "Emergency", "SOS", "CQD", "XXX", "MAYDAY"]
    property var modeLabels: [
        //% "Pulse"
        qsTrId("id-beacon-pulse"),
        //% "Emergency"
        qsTrId("id-cat-emergency"),
        "SOS", "CQD", "XXX", "MAYDAY"
    ]

    // Color ring selector around the collapsed trigger. Placed before the
    // trigger so trigger and mode cycler stack above its touch disc.
    ColorRing {
        id: colorRing
        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight / 2
        width:  Dims.l(90)
        height: Dims.l(90)
        circleDiameter: squareGuard.circleSize
        visible: !beaconOn
    }

    // Mode cycler below the trigger, centered between the color ring's
    // outer edge and the page-dots inset.
    ValueCycler {
        x: squareGuard.x
        y: {
            var ringBottom = colorRing.y + colorRing.height / 2 + colorRing.outerRadius
            var bandBottom = squareGuard.y + squareGuard.height - squareGuard.bottomInset
            return ringBottom + (bandBottom - ringBottom - height) / 2
        }
        width:  squareGuard.width
        height: Dims.l(12)
        visible: !beaconOn
        valueArray:   modeLabels
        currentValue: modeLabels[modeKeys.indexOf(selectedMode)]
        onValueChanged: function(value) {
            selectedMode    = modeKeys[modeLabels.indexOf(value)]
            currentSeq      = sequences[selectedMode]
            speedMultiplier = 1.0
            restartSignal()
        }
    }

    // Beacon trigger, collapsed it matches the collapsed flashlight
    Rectangle {
        id: beaconRect
        anchors.centerIn: parent
        anchors.verticalCenterOffset: DeviceSpecs.flatTireHeight / 2

        // Fullscreen the rect flashes in beaconColor. Collapsed it is the
        // same translucent black circle as the flashlight off state and the
        // quick settings toggles; only the icon pulses then.
        color:   beaconOn ? beaconColor : "#66444444"
        opacity: beaconOn ? signalLevel : 1
        width:   beaconOn ? root.width  : squareGuard.circleSize
        height:  beaconOn ? root.height : squareGuard.circleSize
        radius:  beaconOn ? (DeviceSpecs.hasRoundScreen ? width / 2 : 0) : width / 2

        MouseArea {
            anchors.fill: parent
            property real pressX: 0
            property real pressY: 0
            onPressed: function(mouse) { pressX = mouse.x; pressY = mouse.y }
            onReleased: function(mouse) {
                if (Math.abs(mouse.x - pressX) < Dims.l(3) &&
                    Math.abs(mouse.y - pressY) < Dims.l(3))
                    beaconOn = !beaconOn
            }
        }

        Behavior on width  { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }
    }

    // Glitch-impression prevention: fullscreen, the icon is a slightly
    // darker shade of the beacon color, barely offset from the flashing
    // fill, and it flashes with it. Collapsed it pulses in the color.
    Icon {
        anchors.centerIn: beaconRect
        name: "ios-radio-outline"
        width:  beaconRect.width  * 0.7
        height: beaconRect.height * 0.7
        color:  beaconOn ? Qt.darker(beaconColor, 1.1) : beaconColor
        opacity: beaconOn ? signalLevel : 0.4 + signalLevel * 0.6
    }

    // Pulse animation, always live when pageActive
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

    // Morse timer, always live when pageActive and not Pulse
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

    // Restart the sequence on activation so the pattern begins in its high
    // phase, never on a black frame.
    onBeaconOnChanged: if (beaconOn) restartSignal()

    onPageActiveChanged: {
        if (pageActive) restartSignal()
        else signalTimer.stop()
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

    NonGraphicalFeedback {
        id: scrubFeedback
        event: "press"
    }

    // Drag speed overlay, active while beacon is running
    MouseArea {
        anchors.fill: parent
        enabled: beaconOn && pageActive

        property real pressX:      0
        property real pressY:      0
        property real pressSpeed:  0
        property bool tracking:    false
        property bool axisDecided: false
        property real threshold:   Dims.l(3)

        onPressed: function(mouse) {
            pressX      = mouse.x
            pressY      = mouse.y
            pressSpeed  = speedMultiplier
            tracking    = false
            axisDecided = false
        }

        onPositionChanged: function(mouse) {
            if (axisDecided) {
                if (!tracking) return
            } else {
                var dx = Math.abs(mouse.x - pressX)
                var dy = Math.abs(mouse.y - pressY)
                if (dx < threshold && dy < threshold) return
                axisDecided = true
                if (dx >= dy) {
                    // Input sensing leads, visuals follow, the haptic marks
                    // the moment the scrub grabs, before any value changes.
                    tracking        = true
                    preventStealing = true
                    scrubFeedback.play()
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
        text: "×" + speedMultiplier.toFixed(2)
        font.pixelSize: Dims.l(14)
        color: "#00A698"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
