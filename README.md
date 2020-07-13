[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://en.wikipedia.org/wiki/MIT_License)

# xLib6000
## Mac version of FlexLib (TM) for the FlexRadio (TM) 6000 series software defined radios.
###      (see Evolution below for radio versions that are supported)


### Built on:

*  macOS 10.15.6 Beta (19G46c)
*  Xcode 11.5 (11E608c)
*  Swift 5.2


## Usage

Portions of this code do not work and changes may be added from time to time which will break all or part of this app. 

**NOTE: This code is structured as a Swift Package and should be used as such**


## Comments / Questions

Please send any bugs / comments / questions to douglas.adams@me.com


## Evolution

Flex Radios can have one of four different version groups:
*  v1.x.x, the v1 API - untested at this time
*  v2.0.x thru v2.4.9, the v2 API <<-- CURRENTLY SUPPORTED
*  v2.5.1 to less than v3.0.0, the v3 API without MultiFlex <<-- CURRENTLY SUPPORTED
*  v3.x.x thru v3.1.12, the v3 API with MultiFlex <<-- CURRENTLY SUPPORTED
*  greater than v3.1.12 - untested at this time


## Credits

[![CocoaAsyncSocket](https://img.shields.io/badge/CocoaAsyncSocket-v7.6.3-informational)](https://github.com/robbiehanson/CocoaAsyncSocket)

CocoaAsyncSocket is embedded in this project as source code. It provides TCP and UDP connectivity.


## 1.3.5 Release Notes

* refactored apiState (renamed to state)
* eliminate all @Barrier usage


## 1.3.4 Release Notes

* added removeRemoteTxAudioStream()
* added export() and restore(from:) methods to Interlock & Transmit (future use)
* added Tests for export() and restore(from:)
* removed compression from requestRemoteTxAudioStream()


## 1.3.3 Release Notes

* corrected issue with GuiClient.clientId being reset to nil by later broadcast packets


## 1.3.2 Release Notes

* correction to Fdx Button command to radio
* corrections to Meter handling for UI controls (e.g. Power & SWR indicators)
* corrections to Stream removal process (Audio & IQ streams)


## 1.3.1 Release Notes

* correction for blank GuiClient "station"
* added remoteRxAudioStreamRemove() func
* added updating of known GuiClients
* added defaultFound() func
* many minor corrections / edits
* added WanHasBeenAdded notification


## 1.3.0 Release Notes

* corrected "isForThisClient" functionality in all streams"

Tests executed:

v3.1.8 - all passed except:
 * oldApiTests - n/a
 * TestUsbCable, testUsbCableParse - not implemented
 * testAmplifier - not implemented
 * testRemoteTxAudioStream - uncompressed does not work



## 1.2.11 Release Notes

Tests executed:

v3.1.8 - all passed except:
 * oldApiTests - n/a
 * TestUsbCable, testUsbCableParse - not implemented
 * testAmplifier - not implemented
 * testRemoteTxAudioStream - uncompressed does not work

V2.4.9 - all passed except:
  * newApiTests - n/a
 * TestUsbCable, testUsbCableParse - not implemented
 * testAmplifier - not implemented

