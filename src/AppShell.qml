/*
 * Copyright (C) 2022 - Timo Könnecke <github.com/eLtMosen>
 *               2019 - Florent Revest <revestflo@gmail.com>
 *               2025 - moWerk
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
import org.nemomobile.systemsettings 1.0

Item {
    anchors.fill: parent

    // Instantiated here rather than in main.qml so the D-Bus round-trip to
    // the system settings daemon does not block the first Wayland frame commit.
    Component {
        id: displaySettingsComponent
        DisplaySettings {
            onBrightnessChanged: {
                if (app.startBrightness !== -1) return
                app.startBrightness = brightness
                brightness = maximumBrightness
            }
        }
    }

    Component.onCompleted: {
        app.displaySettings = displaySettingsComponent.createObject(this)
    }

    LayerStack {
        id: layerStack
        firstPage: mainPage
        win: app
    }

    Component {
        id: mainPage
        Item {
            property bool pagesWarmed: false

            Timer {
                interval: 1500
                running:  true
                repeat:   false
                onTriggered: parent.pagesWarmed = true
            }

            ListView {
                id: pageView
                anchors.fill: parent
                orientation: ListView.Horizontal
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                interactive: !app.anyFeatureActive
                clip: true
                cacheBuffer: pageView.width * 10
                model: ["flashlight.qml", "beacon.qml", "strobe.qml", "message.qml"]

                delegate: Item {
                    width:  pageView.width
                    height: pageView.height

                    Loader {
                        anchors.fill: parent
                        active: index === 0 || pagesWarmed
                        source: modelData
                        onLoaded: {
                            item.pageActive = Qt.binding(function() {
                                return pageView.currentIndex === index
                            })
                            if      (index === 0) app.flashlightOn = Qt.binding(function() { return item.flashOn    })
                            else if (index === 1) app.beaconOn     = Qt.binding(function() { return item.beaconOn   })
                            else if (index === 2) app.strobeOn     = Qt.binding(function() { return item.strobeOn   })
                            else if (index === 3) app.messageOn    = Qt.binding(function() { return item.messageOn  })
                        }
                    }
                }
            }

            PageDot {
                dotNumber: 4
                currentIndex: pageView.currentIndex
                anchors {
                    bottom: parent.bottom
                    bottomMargin: Dims.l(4)
                    horizontalCenter: parent.horizontalCenter
                }
                height: Dims.l(3)
                visible: !app.anyFeatureActive
            }
        }
    }
}
