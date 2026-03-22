/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2019 - Florent Revest <revestflo@gmail.com>
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
import Nemo.KeepAlive 1.1

Application {
    id: app

    centerColor: "#00A698"
    outerColor:  "#000C07"

    // Relay properties written by AppShell once its page loaders complete.
    // flashlightOn starts true so the bare white rect is visible from frame 1
    // and anyFeatureActive correctly blocks blanking before AppShell loads.
    property bool flashlightOn: true
    property bool beaconOn:     false
    property bool messageOn:    false
    property bool strobeOn:     false
    property bool anyFeatureActive: flashlightOn || beaconOn || strobeOn || messageOn

    property int startBrightness: -1
    // Instantiated by AppShell after first frame to avoid blocking Wayland commit
    property var displaySettings: null

    onAnyFeatureActiveChanged: DisplayBlanking.preventBlanking = anyFeatureActive
    Component.onDestruction: {
        if (displaySettings) displaySettings.brightness = startBrightness
    }

    // Bare white rect — renders in frame 1, costs nothing to parse.
    // Sits below the AppShell Loader in declaration order so the real
    // flashlight page covers it once loaded.
    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        visible: app.flashlightOn
    }

    // AppShell contains all page navigation, DisplaySettings, LayerStack,
    // and ListView. Activated in onCompleted so its parse cost falls after
    // the first Wayland frame commit.
    Loader {
        id: appShellLoader
        anchors.fill: parent
        active: false
        source: "AppShell.qml"
    }

    Component.onCompleted: {
        DisplayBlanking.preventBlanking = anyFeatureActive
        appShellLoader.active = true
    }
}
