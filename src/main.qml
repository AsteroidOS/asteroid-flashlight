/*
 * SPDX-FileCopyrightText: 2022 Timo Könnecke <github.com/eLtMosen>
 * SPDX-FileCopyrightText: 2019 Florent Revest <revestflo@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.KeepAlive

Application {
    id: app

    centerColor: "#00A698"
    outerColor:  "#000C07"

    // Relayed from the page loader so blanking and swiping react.
    property bool flashlightOn: true
    property bool anyFeatureActive: flashlightOn

    property int startBrightness: -1
    property var displaySettings: dsettings

    DisplayBlanking { preventBlanking: app.anyFeatureActive }

    DisplaySettings {
        id: dsettings
        onBrightnessChanged: {
            if (app.startBrightness !== -1) return
            app.startBrightness = brightness
            brightness = maximumBrightness
        }
    }

    Component.onDestruction: {
        if (startBrightness !== -1)
            dsettings.brightness = startBrightness
    }

    LayerStack {
        id: layerStack
        firstPage: mainPage
        win: app
    }

    Component {
        id: mainPage
        Item {
            ListView {
                id: pageView
                anchors.fill: parent
                orientation: ListView.Horizontal
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                interactive: !app.anyFeatureActive
                clip: true
                cacheBuffer: pageView.width * 10
                model: ["Flashlight.qml"]

                delegate: Item {
                    width:  pageView.width
                    height: pageView.height

                    Loader {
                        anchors.fill: parent
                        source: modelData
                        onLoaded: {
                            item.pageActive = Qt.binding(function() {
                                return pageView.currentIndex === index
                            })
                            if (index === 0) app.flashlightOn = Qt.binding(function() { return item.flashOn })
                        }
                    }
                }
            }
        }
    }
}
