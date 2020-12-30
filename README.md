### xLib6000 [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://en.wikipedia.org/wiki/MIT_License)

#### Mac version of FlexLib (TM) for the Flex 6000 (TM) series radios.

##### Built on:

*  macOS 11.1
*  Xcode 12.3 (12C33)
*  Swift 5.3

##### Runs on:
* macOS 10.15 and higher
* NOTE: for macOS 10.13 or 10.14 use xLib6000 v1.4.0 (which does not contain xLibClient)
* iOS 14 and higher

##### Usage:
xLib6000 is a Swift Package

#### Comments / Questions
Please send any bugs / comments / questions to support@k3tzr.net

##### Flex versions:

Flex Radios can have one of four different version groups:
*  v1.x.x, the ***v1 API*** - untested at this time
*  v2.0.x thru v2.4.9, the ***v2 API*** <<-- CURRENTLY SUPPORTED
*  v2.5.1 to less than v3.0.0, the ***v3 API without MultiFlex*** <<-- CURRENTLY SUPPORTED
*  v3.x.x thru v3.2.14, the ***v3 API with MultiFlex*** <<-- CURRENTLY SUPPORTED
*  greater than v3.2.14 - untested at this time

##### Credits:
[CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) is a package dependency in the xLib6000 target. It provides TCP and UDP connectivity.

##### Other software
[![xSDR6000](https://img.shields.io/badge/K3TZR-xSDR6000-informational)]( https://github.com/K3TZR/xSDR6000) A SmartSDR-like client for the Mac.   
[![DL3LSM](https://img.shields.io/badge/DL3LSM-xDAX,_xCAT,_xKey-informational)](https://dl3lsm.blogspot.com) Mac versions of DAX, CAT and a Remote CW Keyer.  
[![W6OP](https://img.shields.io/badge/W6OP-xVoiceKeyer,_xCW-informational)](https://w6op.com) A Mac-based Voice Keyer and a CW Keyer.  

---
##### 1.6.11 Release Notes
in Radio.swift, correction in parseV3Connection

##### 1.6.10 Release Notes
* in Radio.swift, changed the way guiClient Added / Updated is processed

##### 1.6.9 Release Notes
* in Discovery.swift, changed notSeenInterval default to 10 (from 5)
* in Discovery.swift, changed timer leeway to 250 ms (was 100 ms)

##### 1.6.8 Release Notes
* corrected bug in Radio.swift, parseReply method (line 1003)

##### 1.6.7 Release Notes
* increased iOS deployment from v13 to v14
* changed the name of the Log class to LogProxy

##### 1.6.6 Release Notes
* in WanServer.swift changed sendTestConnection(for packet: DiscoveryPacket) to sendTestConnection(for serialNumber: String)

##### 1.6.5 Release Notes
* removed xLib_iOS and xClient_macOS (created stand-alone packages for them)
* removed dependency on xCGLogger (now in xClient... packages)
* updated CocoaAsyncSocket to require 7.6.5 (fixes iOS 8 issue in xClientIos)

##### 1.6.4 Release Notes
* corrections in xClient_macOS as a result of debugging / changes
* ----->>>>> NOTE: xClient_iOS is not functional at this time

##### 1.6.3 Release Notes
* corrected bug in Discovery line 120

##### 1.6.2 Release Notes
* cleanup comments and formatting (no actual code changes)

##### 1.6.1 Release Notes
* made all stream handling code similar

##### 1.6.0 Release Notes
* replace CocoaAsyncSocket source code with a package reference
* eliminated CocoaAsyncSocket target
* corrected access level for AlertParams initializer

##### 1.5.3 Release Notes
* removed openRadio() and closeRadio from RadioManagerDelegate protocol
* added displayAlert() to RadioManagerDelegate protocol
* modified openRadio() and closeRadio in RadioManager.swift

##### 1.5.2 Release Notes
* removed SwiftyUserDefaults dependencies

##### 1.5.1 Release Notes
* added XCGLogger and SwiftyUserDefaults dependencies

##### 1.5.0 Release Notes
* added xLibClient target

##### 1.4.0 Release Notes
* raised the supported version to 3.2.14
* added "connectionString" computed property to DiscoveryPacket
* updated log messages to use connectionString consistently

##### 1.3.11 Release Notes
* changed discoveredRadios to discoveryPackets throughout
* reworked guiClients
* edited log messages throughout for consistency

##### 1.3.10 Release Notes
* temporary version for testing

##### 1.3.9 Release Notes
* refactor of Discovery code related to GuiClients
* chages throughout to make log message more consistent

##### 1.3.8 Release Notes
* correction to guiClientHasBeenRemoved notification (note.object was nil)

##### 1.3.7 Release Notes
* added findFirstSlice(...) method in RadioExtensions.swift (needed for xMini)
* changes throughout to reduce the number of KVO updates

##### 1.3.6 Release Notes
* changed tcpFirstPingReceived to tcpPingReceived (now sends notification after 2nd ping response)
* delayed Side View opening to tcpPingReceived (corrects crash on startup)
* corrected frequency conversion extentions (uses Double now vs Float earlier) to correct 1 Hz frequency errors
* corrected slice audioGain to deal with v2 vs v3 differences

##### 1.3.5 Release Notes
* refactored apiState (renamed to state)
* eliminate all @Barrier usage

##### 1.3.4 Release Notes
* added removeRemoteTxAudioStream()
* added export() and restore(from:) methods to Interlock & Transmit (future use)
* added Tests for export() and restore(from:)
* removed compression from requestRemoteTxAudioStream()

##### 1.3.3 Release Notes
* corrected issue with GuiClient.clientId being reset to nil by later broadcast packets

##### 1.3.2 Release Notes
* correction to Fdx Button command to radio
* corrections to Meter handling for UI controls (e.g. Power & SWR indicators)
* corrections to Stream removal process (Audio & IQ streams)

##### 1.3.1 Release Notes
* correction for blank GuiClient "station"
* added remoteRxAudioStreamRemove() func
* added updating of known GuiClients
* added defaultFound() func
* many minor corrections / edits
* added WanHasBeenAdded notification

##### 1.3.0 Release Notes
* corrected "isForThisClient" functionality in all streams"

##### 1.2.11 Release Notes
