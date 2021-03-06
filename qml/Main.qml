import Ergo 0.0
import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtMultimedia 5.9
import QtQuick.Window 2.0
import Qt.labs.settings 1.0 as QLS

import "components"
import "controls"
import "pages"

import "UPnP.js" as UPnP

Window {
    id: app
    objectName: 'mainView'

    property alias settings: settings
    property alias audio: audio

    // for desktop testing
    width: units.dp(480)
    height: units.dp(640)

    // Use these colors for the UI.
    readonly property color fgColor: "#232323"
    readonly property color bgColor: "#efefef"

    property color text1color: "#E95420" // Ubuntu orange
    property color text2color: "#333333" // some dark grey 
    property color text3color: "#aea79f" // some light grey 

    property color primaryColor: text1color
    property color secondaryColor: text2color

    property int fontPixelSizeExtraLarge: units.dp(16)
    property int fontPixelSizeLarge: units.dp(14)
    property int fontPixelSizeMedium: units.dp(12)
    property int fontPixelSizeSmall: units.dp(10)
    property int fontPixelSizeExtraSmall: units.dp(8)

    property int fontSizeExtraLarge: fontPixelSizeExtraLarge
    property int fontSizeLarge: fontPixelSizeLarge
    property int fontSizeMedium: fontPixelSizeMedium 
    property int fontSizeSmall: fontPixelSizeSmall
    property int fontSizeExtraSmall: fontPixelSizeExtraSmall

    //
    // UI stuff
    //
    property double paddingExtraSmall: units.dp(2)
    property double paddingSmall: units.dp(4)
    property double paddingMedium: units.dp(8)
    property double paddingLarge: units.dp(16)

    property double iconSizeSmall: units.dp(16)
    property double iconSizeMedium: units.dp(32)
    property double iconSizeLarge: units.dp(80)

    property double itemSizeMedium: units.dp(32)
    //property int itemSize: units.dp(56) page header
    property double itemSizeLarge: units.dp(80)

    property color normalBackgroundColor: "white" // theme.palette.normal.base
    property color highlightBackgroundColor: "#CDCDCD" // theme.palette.highlited.base

    property color nonTransparentBackgroundColor: "white"
    property color controlBackgroundColor: settings.use_albumart_as_background 
        ? "transparent" : nonTransparentBackgroundColor
    property color controlBorderColor: "black"
    property int controlRadius: 3

    property var fontPrimaryWeight: Font.Light
    property var fontHighlightWeight: Font.Bold

    property color popupBackgroundColor: "#111111"
    property double popupBackgroundOpacity: 0.1
    property double popupRadius: units.dp(8)

    property double buttonHeight: itemSizeMedium
    property double checkBoxHeight: itemSizeMedium
    property double comboBoxHeight: itemSizeMedium
    property double labelHeight: itemSizeMedium
    property double textFieldHeight: itemSizeMedium

    // 0 inactive, 1 load queue data, 2 load browse stack data
    property int resumeState: 0

    property bool showBusy: false

    title: i18n.tr("Donnie")
    visible: true

    StackView {
        id: pageStack
        anchors {
            bottom: playerArea.top
            fill: undefined
            left: parent.left
            right: parent.right
            top: parent.top
        }
        clip: true

        Component.onCompleted: {
            pageStack.push(Qt.resolvedUrl("pages/Menu.qml"))
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        width: itemSizeLarge
        height: width
        running: showBusy
    }

    PlayerArea {
        id: playerArea
        height: visible ? childrenRect.height : 0
        width: parent.width
        audio: audio
        visible: pageStack.currentItem.objectName != "PlayerPage"
        trackMetaText1: getPlayerPage().trackMetaText1
        trackMetaText2: getPlayerPage().trackMetaText2
        imageSource: app.getPlayerPage().imageItemSource
        onPlayPause: app.playPause()
    }

    Image {
        anchors.fill: parent
        //z: -1
        fillMode: Image.PreserveAspectCrop
        opacity: 0.1
        source: app.getPlayerPage().imageItemSource
        visible: settings.use_albumart_as_background
    }

    signal previous()
    signal next()

    signal audioBufferFull()
    onAudioBufferFull: play()

    Audio {
        id: audio

        autoLoad: true
        autoPlay: true
        //source: channelStreamUrl

        onError: {
            console.log("Audio Player error:" + errorString)
            console.log("source: " + source)
            showErrorDialog(i18n.tr("Audio Player:") + "\n\n" + errorString)
        }
    }

    function updateMprisMetaData(meta) {
        audio.metaData.title = meta.Title
        audio.metaData.albumTitle = meta.Album
        audio.metaData.albumArtist = meta.Artist
        audio.metaData.coverArtUrlSmall = meta.ArtUrl
        audio.metaData.coverArtUrlLarge = meta.ArtUrl
        audio.metaData.trackNumber = meta.TrackNumber
    }

    function playPause() {
        console.log("pause() audio.source:" + audio.source)
        if(audio.playbackState === Audio.PlayingState)
            audio.pause()
        else
          audio.play()
    }
    
    function checkHasCurrentServer() {
        if(!hasCurrentServer()) {
            showMessageDialog(i18n.tr("Error"), i18n.tr("No UPnP Server found")) 
            return false
        }
        return true
    }

    function doSelectedMenuItem(id) {
        switch(id) {
            case "upnp-discovery": 
                pageStack.push(Qt.resolvedUrl("pages/Discovery.qml"))
                break
            case "upnp-browse": 
                if(checkHasCurrentServer()) {
                    if(browsePage.cid == "")
                        browsePage.cid = "0"
                    pageStack.push(browsePage)
                }
                break
            case "builtin-player": 
                if(checkHasCurrentServer()) 
                    pageStack.push(playerpage)
                break
            case "upnp-search": 
                pageStack.push(Qt.resolvedUrl("pages/Search.qml"),
                    {searchCapabilities: app.currentServerSearchCapabilities})
                break
            case "about": 
                pageStack.push(Qt.resolvedUrl("pages/About.qml"))
                break
            case "help": 
                pageStack.push(Qt.resolvedUrl("pages/Help.qml"))
                break
            case "settings": 
                pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
                break
        }
    }

    function pushPage(url, options) {
        return pageStack.push(Qt.resolvedUrl(url), options)
    }

    // trial and error and interweb
    function gu(value) {
        return units.dp(8) * value
    }

    function error(msg) {
        console.log("error: " + msg)
        //errorLog.push(msg);
    }

    Browse {
        id: browsePage
        visible: false
    }
    
    PlayerPage {
        id: playerpage
        visible: false
        audio: audio
    }

    function getPlayerPage() {
        return playerpage
    }

    property var discoveredRenderers : []
    property var discoveredServers : []
    property var currentBrowseStack : new UPnP.dataStructures.Stack()
    property var currentServer: null
    property var currentRenderer: null
    property var currentServerSearchCapabilities
    property bool useBuiltInPlayer: true

    function hasCurrentServer() {
        return app.currentServer ? true : false
    }

    function setCurrentServer(server) {
        app.currentServer = server
        console.log("setCurrentServer to: "+ currentServer["friendlyName"])
        var res = upnp.setCurrentServer(currentServer["friendlyName"], true)
        currentServerSearchCapabilities = []
        if(res) {
            try {
                var i
                var scapJson = upnp.getSearchCapabilitiesJson()
                console.log(scapJson)
                var allSearchCaps = JSON.parse(scapJson)
                // minidlna worked well but minimserver returned some search capabilities that
                // when used the query made it return an error
                // things like: @refID, upnp:class, upnp:artist[@role="AlbumArtist"]
                for(i=0;i<allSearchCaps.length;i++) {
                    if(allSearchCaps[i] !== "upnp:class"
                       && allSearchCaps[i].indexOf('@') < 0)
                        currentServerSearchCapabilities.push(allSearchCaps[i])
                }
            } catch( err ) {
                app.error("Exception while getting Search Capabilities: " + err)
                app.error("json: " + scapJson)
            }
        } else {
            error("Failed to set Current Server to: "+ currentServer["friendlyName"])
        }
        return res
    }

    function hasCurrentRenderer() {
        return app.currentRenderer ? true : false
    }

    function setCurrentRenderer(renderer) {
        app.currentRenderer = renderer

        if(renderer === undefined) {
            rendererPage.reset()
            return
        }

        console.log("setCurrentRenderer to: "+ currentRenderer["friendlyName"])
        var res = upnp.setCurrentRenderer(currentRenderer["friendlyName"], true)
        if(!res) {
            rendererPage.reset()
            error("Failed to set Current Renderer to: "+ currentRenderer["friendlyName"])
        }
        return res
    }

    function searchForRendererAndServer() {
        var started = false
        // check if configured renderer and server can be reached
        if(settings.renderer_friendlyname && settings.renderer_udn !== "donnie-player-udn") {
            upnp.getRendererJson(settings.renderer_friendlyname, settings.search_window)
            started = true
        }
        else if(settings.renderer_friendlyname && settings.renderer_udn === "donnie-player-udn")
            app.useBuiltInPlayer = true
        if(settings.server_friendlyname) {
            upnp.getServerJson(settings.server_friendlyname, settings.search_window)
            started = true
        }
        showBusy = started
    }
    
    Component.onCompleted: searchForRendererAndServer()

    Connections {
        target: upnp

        onGetRendererDone: {
            var i;

            try {
                var devices = JSON.parse(rendererJson);

                if(devices["renderer"] && devices["renderer"].length>0)
                    app.setCurrentRenderer(devices["renderer"][0]);
            } catch(err) {
                app.error("Exception in onGetRendererDone: "+err);
                app.error("json: " + rendererJson);

            }

            //showBusy = false; // VISIT both should be done
        }

        onGetServerDone: {
            var i;

            try {
                var devices = JSON.parse(serverJson);

                if(devices["server"] && devices["server"].length>0)
                    app.setCurrentServer(devices["server"][0]);
            } catch(err) {
                app.error("Exception in onGetServerDone: "+err);
                app.error("json: " + serverJson);
            }

            showBusy = false; // VISIT both should be done

            if(app.hasCurrentServer()) {
                if(settings.resume_saved_info === 1) // 0: never, 1: ask, 2:always
                    app.showConfirmDialog(i18n.tr("Load previously saved queue?"), i18n.tr("Load"), function() {
                        loadResumeMetaData()
                    })
                else if(settings.resume_saved_info === 2)
                    loadResumeMetaData()
            } else
              showMessageDialog(i18n.tr("Warning"), i18n.tr("No UPnP Server found")) 
        }

        onError: {
            showBusy = false; // VISIT only one could fail
            showErrorDialog(i18n.tr("UPnP Error") + ": " + msg) 
            console.log("Main::onError: " + msg);
            app.error(msg);
        }

        // called when metadata has been collected from stored resume info
        onMetaData: {
            //console.log("onMetaData: " + metaDataJson);
            if(error !== 0) {
                app.showErrorDialog(qsTr("Failed to retrieve metadata for previously saved Ids.\nCan not Resume."))
                //showBusy = false
                if(resumeState == 1)
                    loadBrowseStackMetaData()
                else
                    resumeState = 0
                return
            }

            try {
                var metaData = JSON.parse(metaDataJson);

                switch(resumeState) {
                case 1:
                    // restore queue and current track
                    var currentTrackIndex = -1
                    var tracks = []
                    var i
                    var track
                    // todo: getPlayerPage().reset() but does not exist

                    // create items for stored id's
                    for(i=0;i<metaData.length;i++) {
                        if(metaData[i].items && metaData[i].items.length>0) {
                            track = UPnP.createListItem(metaData[i].items[0])
                            tracks.push(track)
                            if(track.id === metaDataCurrentTrackId)
                                currentTrackIndex = tracks.length - 1
                        }
                    }

                    // create items for user added uris
                    for(i=0;i<userDefinedItems.length;i++) {
                        track = UPnP.createUserAddedTrack(userDefinedItems[i].data.uri,
                                                          userDefinedItems[i].data.title,
                                                          userDefinedItems[i].data.streamType)
                        tracks.splice(userDefinedItems[i].index, 0, track)
                        if(track.id === metaDataCurrentTrackId)
                            currentTrackIndex = tracks.length - 1
                    }

                    metaDataCurrentTrackId = ""

                    getPlayerPage().addTracks(tracks,
                                              currentTrackIndex,
                                              UPnP.isBroadcast(track) ? -1 : settings.last_playing_position)
                    loadBrowseStackMetaData()
                    break;

                case 2:
                    // restore browse stack
                    var index = 0
                    browsePage.reset()
                    browsePage.pushOnBrowseStack("0", "-1", qsTr("[Top Level]"), -1);
                    for(var i=0;i<metaData.length;i++) {
                        if(metaData[i].containers && metaData[i].containers.length>0) {
                            var item = metaData[i].containers[0]
                            browsePage.pushOnBrowseStack(item.id, item.pid, item.title, index);
                            index++
                        }
                    }
                    browsePage.cid = app.currentBrowseStack.peek().id
                    resumeState = 0
                    break;
                }
                //showBusy = false
            } catch(err) {
                app.error("Exception in onMetaData: "+err);
                app.error("json: " + metaDataJson);
                app.showErrorDialog(qsTr("Failed to parse previously saved Ids.\nCan not Resume."))
                //showBusy = false
            }
        }
    }

    function loadLastBrowsingJSON() {
        try {
            var lastBrowsingInfo = JSON.parse(settings.last_browsing_info)
            return lastBrowsingInfo
        } catch( err ) {
            app.error("Exception in loadLastBrowsingJSON: " + err)
            app.error("json: " + settings.last_browsing_info)
        }
        return null
    }

    function loadLastPlayingJSON() {
        try {
            var lastPlayingInfo = JSON.parse(settings.last_playing_info)
            return lastPlayingInfo
        } catch( err ) {
            app.error("Exception in loadLastPlayingJSON: " + err)
            app.error("json: " + settings.last_playing_info)
        }
        return null
    }

    function loadBrowseStackMetaData() {
        var i
        //showBusy = true
        try {
            var linfo = loadLastBrowsingJSON()
            if(linfo !== null && linfo.length > 0) {
                var pos = 0
                var ids = []
                for(i=0;i<linfo.length;i++)
                    ids[pos++] = linfo[i]
                if(ids.length > 0) {
                    resumeState = 2
                    upnp.getMetaData(ids)
                }
            }
        } catch(err) {
            app.error("Exception in loadBrowseStackMetaData: "+err);
            app.showErrorDialog(qsTr("Failed to load previously saved Browse Stack Ids."))
            //showBusy = false
        }
    }

    property string metaDataCurrentTrackId
    property var userDefinedItems : []

    function loadResumeMetaData() {
        var i
        try {
            var linfo = loadLastPlayingJSON()
            if(linfo !== null && linfo.currentTrackId && linfo.queueTrackIds) {
                var pos = 0
                var ids = []

                metaDataCurrentTrackId = linfo.currentTrackId

                userDefinedItems = []
                for(i=0;i<linfo.queueTrackIds.length;i++) {
                    if(linfo.queueTrackIds[i].dtype === "cs")
                        ids[pos++] = linfo.queueTrackIds[i].data
                    else if(linfo.queueTrackIds[i].dtype === "ud")
                        userDefinedItems.push({index: i, data: linfo.queueTrackIds[i].data})
                }

                if(ids.length > 0) {
                    resumeState = 1
                    upnp.getMetaData(ids)
                }
            }
        } catch(err) {
            app.error("Exception in loadResumeMetaData: "+err);
            app.showErrorDialog(qsTr("Failed to load previously saved Queue Ids.\nCan not Resume."))
        }
        if(resumeState == 0) // not loading the queue
            loadBrowseStackMetaData()
    }

    function saveLastBrowsingJSON() {
        var i
        var browseStackIds = []
        for(i=1;i<currentBrowseStack.length();i++)
            browseStackIds.push(currentBrowseStack.elements()[i].id)
        settings.last_browsing_info = JSON.stringify(browseStackIds)
    }

    function saveLastPlayingJSON(currentTrack, trackListModel) {
        /*
          info.currentTrackId
          info.queueTrackIds[]
         */
        var i
        var lastPlayingInfo = {}
        lastPlayingInfo.currentTrackId = currentTrack.id
        lastPlayingInfo.queueTrackIds = []
        for(i=0;i<trackListModel.count;i++) {
            var item = trackListModel.get(i)
            var info
            if(item.dtype === UPnP.DonnieItemType.ContentServer)
                info = { dtype: "cs", data: item.id}
            else
                info = { dtype: "ud", data: { title: item.title, uri: item.uri, streamType: item.upnpclass}}
            lastPlayingInfo.queueTrackIds.push(info)
        }
        settings.last_playing_info = JSON.stringify(lastPlayingInfo)
    }

    //
    // Dialogs
    //

    Component {
        id: dialogFactory

        Dialog {
            id: dialog

            property string messageTitle: ""
            property string messageText: ""
            property bool confirmation: false
            property var acceptedCallback: null

            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            title: messageTitle
            modal: true

            //height: app.fontPixelSizeMedium * 9
            //height: app.height / 3

            header: Label { // copied from Qt, added font.pixelSize
                text: dialog.title
                visible: dialog.title
                elide: Label.ElideRight
                font.bold: true
                font.pixelSize: app.fontPixelSizeMedium
                
                leftPadding: app.paddingLarge
                topPadding: app.paddingSmall
                bottomPadding: app.paddingSmall

                background: Rectangle {
                    //x: 1; y: 1
                    width: parent.width //- 2
                    height: parent.height //- 1
                    border.color: app.controlBorderColor
                    border.width: 1
                    radius: app.controlRadius
                    color: app.nonTransparentBackgroundColor
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: dialog.messageText
                font.pixelSize: app.fontPixelSizeMedium
                leftPadding: app.paddingMedium
                rightPadding: leftPadding
                topPadding: app.paddingLarge
                bottomPadding: topPadding
            }

            background: Rectangle {
                border.color: app.controlBorderColor
                border.width: 1
                radius: app.controlRadius
                color: app.nonTransparentBackgroundColor
            }

            footer: DialogButtonBox {
                id: dbBox
                height: app.fontPixelSizeMedium * 4
                padding: app.paddingMedium
                alignment: Qt.AlignRight 

                property int buttonHeight: dbBox.height / 2
                property int buttonWidth: dbBox.width / 3

                Component.onCompleted: {
                    //console.log("dbox w="+width+",x="+x)
                    //console.log("parent w="+parent.width)
                    //console.log("content w="+contentItem.width+",x="+contentItem.x)
                    background.color = app.nonTransparentBackgroundColor
                }

                MyButton {
                    id: acceptButton
                    height: dbBox.buttonHeight
                    width: dbBox.buttonWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: confirmation ? i18n.tr("Yes") : i18n.tr("Ok")
                    DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                    //backgroundColor: app.nonTransparentBackgroundColor
                }

                MyButton {
                    id: rejectButton
                    height: dbBox.buttonHeight
                    width: dbBox.buttonWidth
                    anchors.verticalCenter: parent.verticalCenter
                    visible: confirmation
                    text: i18n.tr("No")
                    DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                    //backgroundColor: app.nonTransparentBackgroundColor
                }

                /*background: Rectangle {
                    anchors.fill: parent          
                    border.color: app.controlBorderColor
                    border.width: 1
                    radius: app.controlRadius
                    color: app.controlBackgroundColor
                }*/
            }

            onAccepted: {
                if(acceptedCallback != null)
                    acceptedCallback()
            }
        }
    }

    function showConfirmDialog(text, title, callback) {
        var dialog = dialogFactory.createObject(app, { 
            messageTitle: title, 
            messageText: text, 
            confirmation: true, 
            acceptedCallback: callback
        })
        dialog.open()
    }

    function showMessageDialog(title, text) {
        var dialog = dialogFactory.createObject(app, { 
            messageTitle: title, 
            messageText: text, 
            confirmation: false, 
        })
        dialog.open()
    }

    function showErrorDialog(text) {
        showMessageDialog(i18n.tr("Error"), text)
    }

    //
    // Settings
    //
    QLS.Settings {
        id: settings

        property int search_window: 5
        property int max_number_of_results: 200
        property string server_udn : ""
        property string server_friendlyname : ""
        property string server_use_nexturi : ""
        property string renderer_udn : ""
        property string renderer_friendlyname : ""
        property string last_browsing_info: ""
        property string last_playing_info: ""
        property int last_playing_position: 0
        property int resume_saved_info: 0
        property bool search_allow_containers: false
        property int selected_search_capabilities: 0xFFF
        property string groupby_search_results: "album"
        property bool use_albumart_as_background: true
    }
}
