[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://en.wikipedia.org/wiki/MIT_License)

# xLib6000
## Mac version of FlexLib (TM) for the FlexRadio (TM) 6000 series software defined radios.
###      (see Evolution below for radio versions that are supported)


### Built on:

*  macOS 10.15.4
*  Xcode 11.4.1 (11E503a)
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
*  v3.x.x thru v3.1.8, the v3 API with MultiFlex <<-- CURRENTLY SUPPORTED
*  greater than v3.1.8 - untested at this time


## Credits

[![CocoaAsyncSocket](https://img.shields.io/badge/CocoaAsyncSocket-v7.6.3-informational)](https://github.com/robbiehanson/CocoaAsyncSocket)

CocoaAsyncSocket is embedded in this project as source code. It provides TCP and UDP connectivity.


## 1.2.10 Release Notes

* Options for Multiflex connections (correction to support this)


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

