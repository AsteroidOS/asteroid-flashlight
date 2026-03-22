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
import QtSensors 5.11
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

Item {
    id: root
    property bool pageActive: false
    property bool messageOn:  false

    // ── Speed state — reset on every string change ──────────────────────────
    property real userPixelsPerSecond: 300
    property real blinkCycleMs:        1200
    // ────────────────────────────────────────────────────────────────────────

    // ── Category metadata ───────────────────────────────────────────────────
    property bool isBlinkMode: catIndex === 4
    property bool isSmallFont: catIndex === 4 || catIndex === 5
    // ────────────────────────────────────────────────────────────────────────

    // ── Horizon lock ─────────────────────────────────────────────────────────
    // Smoothed gravity components. Smoothing factor 0.1 damps jitter while
    // still following deliberate arm movement within ~300ms.
    property real smoothedX:  0
    property real smoothedY:  0
    // Roll angle in degrees. 0 = watch upright (12 o'clock up).
    // Positive = clockwise tilt when looking at the watch face.
    // atan2(x, -y): when upright gravity is in -Y, x≈0 → atan2(0,-(-g))=0.
    // Note: if rotation appears reversed on device, negate smoothedX here.
    property real rollAngle: Math.atan2(smoothedX, smoothedY) * 180 / Math.PI

    Accelerometer {
        id: accel
        // Only active while the banner is fullscreen — zero cost otherwise
        active: messageOn && pageActive
        dataRate: 30
        onReadingChanged: {
            root.smoothedX = root.smoothedX + 0.4 * (reading.x - root.smoothedX)
            root.smoothedY = root.smoothedY + 0.4 * (reading.y - root.smoothedY)
        }
    }

    onMessageOnChanged: {
        if (!messageOn) {
            // Let the Behavior animate back to upright
            smoothedX = 0
            smoothedY = 0
        }
    }
    // ────────────────────────────────────────────────────────────────────────

    anchors.fill: parent
    clip: true

    // ── Data ────────────────────────────────────────────────────────────────
    property var categories: [
        //% "Emergency"
        qsTrId("id-cat-emergency"),
        //% "Navigation"
        qsTrId("id-cat-navigation"),
        //% "Social"
        qsTrId("id-cat-social"),
        //% "Fun"
        qsTrId("id-cat-fun"),
        "Emoji",
        "Kaomoji"
    ]

    property var messages: [
        // Emergency
        [
            //% "Help"
            qsTrId("id-msg-help"),
            //% "Call 911"
            qsTrId("id-msg-call-911"),
            //% "Need help"
            qsTrId("id-msg-need-help"),
            //% "Lost"
            qsTrId("id-msg-lost"),
            //% "Injured"
            qsTrId("id-msg-injured")
        ],
        // Navigation
        [
            //% "Follow me"
            qsTrId("id-msg-follow-me"),
            //% "This way"
            qsTrId("id-msg-this-way"),
            //% "Come over"
            qsTrId("id-msg-come-over"),
            //% "Stay back"
            qsTrId("id-msg-stay-back")
        ],
        // Social
        [
            //% "Let's go!"
            qsTrId("id-msg-lets-go"),
            //% "Taxi!"
            qsTrId("id-msg-taxi"),
            //% "Encore!"
            qsTrId("id-msg-encore"),
            //% "Quiet!"
            qsTrId("id-msg-quiet"),
            //% "Oi!"
            qsTrId("id-msg-oi"),
            //% "Over here!"
            qsTrId("id-msg-over-here")
        ],
        // Fun
        [
            //% "Boooring"
            qsTrId("id-msg-boooring"),
            //% "Free hugs"
            qsTrId("id-msg-free-hugs"),
            //% "Burp!"
            qsTrId("id-msg-burp"),
            //% "Plot twist!"
            qsTrId("id-msg-plot-twist")
        ],
        // Emoji — blink mode, no translation
        ["\uD83D\uDD25", "\uD83D\uDE80", "\uD83C\uDF89",
        "\uD83D\uDCA9", "\uD83D\uDC80", "\uD83E\uDD21"],
        // Kaomoji — scroll mode, no translation
        ["\u00AF\\_(\u30C4)_/\u00AF",
        "(\u256F\u00B0\u25A1\u00B0\uFF09\u256F\uFE35 \u253B\u2501\u253B",
        "( \u0361\u00B0 \u035C\u0296 \u0361\u00B0)",
        "(^_^)",
        "<(^_^<)"]
    ]

    property int catIndex: 0
    property int msgIndex: 0

    function resetSpeed() {
        userPixelsPerSecond = 900
        blinkCycleMs        = 1200
    }
    // ────────────────────────────────────────────────────────────────────────

    //% "Message"
    PageHeader {
        text: qsTrId("id-message")
        visible: !messageOn
    }

    // Category cycler — pushed off screen upward when trigger expands
    ValueCycler {
        id: categoryCycler
        anchors {
            bottom:       messageRect.top
            bottomMargin: Dims.l(1)
            left:         parent.left
            right:        parent.right
        }
        height: Dims.l(16)
        valueArray:   categories
        currentValue: categories[catIndex]
        onValueChanged: {
            catIndex = categories.indexOf(value)
            msgIndex = 0
            resetSpeed()
        }
    }

    // ── Trigger rect ─────────────────────────────────────────────────────────
    Rectangle {
        id: messageRect
        anchors.centerIn: parent
        color: "#000000"
        width:  messageOn ? root.width  : Dims.w(40)
        height: messageOn ? root.height : Dims.w(40)
        radius: messageOn
        ? (DeviceSpecs.hasRoundScreen ? width / 2 : 0)
        : Dims.l(4)
        clip: true

        // Horizon lock: rotate content so text stays parallel to ground.
        // Only applied while active — idle preview always shows upright.
        // Behavior animates back to 0 on deactivation.
        rotation: messageOn ? root.rollAngle : 0
        Behavior on rotation {
            NumberAnimation { duration: 200; easing.type: Easing.Linear }
        }

        // ── Scroll content ───────────────────────────────────────────────────
        BannerScroll {
            id: bannerScroll
            anchors.centerIn: parent
            // Vertical offset compensates for font descender padding in Qt Text item
            anchors.verticalCenterOffset: messageOn ? -Dims.l(3) : -Dims.l(1.54)
            width:  parent.width
            height: messageOn
            ? Dims.l(100)
            : Dims.l(40)
            visible: !root.isBlinkMode
            message: messages[catIndex][msgIndex]
            fontSize: {
                var base = messageOn
                ? Dims.l(100)
                : Dims.l(40)
                return root.isSmallFont ? base * 0.75 : base
            }
            dimsPerSecond: messageOn
            ? root.userPixelsPerSecond / Dims.l(1)
            : 80
            scrolling: pageActive && !root.isBlinkMode
        }

        // ── Blink content — Emoji only ────────────────────────────────────────
        Label {
            id: blinkLabel
            anchors.centerIn: parent
            // Vertical offset compensates for font descender padding in Qt Text item
            anchors.verticalCenterOffset: messageOn ? -Dims.l(10) : -Dims.l(2.5)
            visible: root.isBlinkMode
            text: root.isBlinkMode ? messages[catIndex][msgIndex] : ""
            font.pixelSize: {
                var base = messageOn
                ? Dims.l(100)
                : Dims.l(40)
                return base * 0.81
            }
            verticalAlignment: Text.AlignVCenter
            opacity: 1.0
        }

        // 0 bpm = static full opacity.
        // Otherwise: cycle = 60000/bpm ms, fade to 0.3 over 2/3, back to 1.0 over 1/3.
        // Restarted on blinkCycleMs change so duration updates take effect immediately.
        SequentialAnimation {
            id: blinkAnim
            running: root.isBlinkMode && pageActive && root.blinkCycleMs > 0
            loops:   Animation.Infinite
            onRunningChanged: if (!running) blinkLabel.opacity = 1.0

            NumberAnimation {
                target: blinkLabel; property: "opacity"
                to: 0.2; duration: root.blinkCycleMs * 0.67
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: blinkLabel; property: "opacity"
                to: 1.0; duration: root.blinkCycleMs * 0.33
                easing.type: Easing.InOutQuad
            }
        }

        Connections {
            target: root
            onBlinkCycleMsChanged: {
                if (root.isBlinkMode && root.blinkCycleMs > 0) {
                    blinkAnim.restart()
                } else {
                    blinkAnim.stop()
                    blinkLabel.opacity = 1.0
                }
            }
        }

        // Activation only — deactivation handled by root overlay below
        MouseArea {
            anchors.fill: parent
            enabled: !messageOn
            onClicked: messageOn = true
        }

        Behavior on width  { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.InCurve  } }
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }
    }
    // ────────────────────────────────────────────────────────────────────────

    // Message cycler — pushed off screen downward when trigger expands
    ValueCycler {
        id: messageCycler
        anchors {
            top:       messageRect.bottom
            topMargin: Dims.l(2)
            left:      parent.left
            right:     parent.right
        }
        height: Dims.l(16)
        valueArray:   messages[catIndex]
        currentValue: messages[catIndex][msgIndex]
        onValueChanged: {
            msgIndex = messages[catIndex].indexOf(value)
            resetSpeed()
        }
    }

    // ── Full-screen drag overlay ──────────────────────────────────────────────
    // Touch deltas are in screen coordinates. We rotate them by -pressAngle
    // so "along the scroll direction" always maps to speed change regardless
    // of watch orientation. The axis is locked at press time so mid-drag
    // arm wobble doesn't confuse the direction.
    MouseArea {
        anchors.fill: parent
        enabled: messageOn && pageActive

        property real pressX:          0
        property real pressY:          0
        property real pressSpeed:      0
        property real pressBlinkCycle: 0
        property real pressAngle:      0   // rollAngle snapshotted at press
        property bool tracking:        false
        property bool axisDecided:     false
        property real threshold:       Dims.l(3)

        onPressed: {
            pressX          = mouse.x
            pressY          = mouse.y
            pressSpeed      = root.userPixelsPerSecond
            pressBlinkCycle = root.blinkCycleMs
            pressAngle      = root.rollAngle   // lock axis to current orientation
            tracking        = false
            axisDecided     = false
        }

        onPositionChanged: {
            var dx = mouse.x - pressX
            var dy = mouse.y - pressY

            if (!axisDecided) {
                if (Math.sqrt(dx*dx + dy*dy) < threshold) return
                    axisDecided = true

                    // Rotate delta into messageRect coordinate space
                    var rad        = -pressAngle * Math.PI / 180
                    var scrollAxis = dx * Math.cos(rad) - dy * Math.sin(rad)
                    var crossAxis  = dx * Math.sin(rad) + dy * Math.cos(rad)

                    if (Math.abs(scrollAxis) >= Math.abs(crossAxis)) {
                        tracking        = true
                        preventStealing = true
                    } else {
                        // Cross-axis gesture — let ListView handle it
                        mouse.accepted = false
                        return
                    }
            }

            if (!tracking) return

                // Project onto scroll axis locked at press time
                var r     = -pressAngle * Math.PI / 180
                var delta = dx * Math.cos(r) - dy * Math.sin(r)

                if (root.isBlinkMode) {
                    root.blinkCycleMs = Math.max(300, Math.min(1500, pressBlinkCycle - delta / 1.5))
                } else {
                    root.userPixelsPerSecond = Math.max(160, Math.min(1500, pressSpeed - delta / 1.5))
                }
                speedLabel.opacity = 1
        }

        onReleased: {
            if (!tracking) messageOn = false
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

    // Speed / blink indicator — screen-upright (outside messageRect, not rotated).
    // enabled: false so it never intercepts taps.
    Label {
        id: speedLabel
        anchors {
            verticalCenter:   parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        visible: messageOn
        enabled: false
        rotation: messageOn ? root.rollAngle : 0
        text: root.isBlinkMode ? (root.blinkCycleMs > 0 ? Math.round(60000 / root.blinkCycleMs) + " bpm" : "static") : Math.round(root.userPixelsPerSecond) + " px/s"
        font.pixelSize: Dims.l(14)
        color: "#00A698"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    // ────────────────────────────────────────────────────────────────────────
}
