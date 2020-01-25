[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://en.wikipedia.org/wiki/MIT_License)

# xLib6000
## Mac version of FlexLib (TM) for the FlexRadio (TM) 6000 series software defined radios.
###      (currently supports Radios with Version 2.4.9 or lower, see Evolution below)


### Built on:

*  macOS 10.14.6 (Deployment Target of macOS 10.11)
*  Xcode 11.3.1 (11C504)
*  Swift 5.1.3


## Usage

Portions of this code do not work and changes may be added from time to time which will break all or part of this app. 

**NOTE: This code is structured as a Swift Package and should be used as such.


## Comments / Questions

Please send any bugs / comments / questions to douglas.adams@me.com


## Evolution

Please see ChangeLog.txt for a running list of changes.

This version currently supports Radios using the Flex v2 API. A Future version of this code will support all Radio versions.

Flex Radios can have one of four different version groups:
*  v1.x.x, the v1 API
*  v2.0.x thru v2.4.9, the v2 API <<-- CURRENTLY SUPPORTED
*  v2.5.1 to less than v3.0.0, the v3 API without MultiFlex <<-- COMING
*  v3.x.x, the v3 API with MultiFlex <<-- COMING


## Credits

[![CocoaAsyncSocket](https://img.shields.io/badge/CocoaAsyncSocket-v7.6.3-informational)](https://github.com/robbiehanson/CocoaAsyncSocket)

CocoaAsyncSocket is embedded in this project as source code. It provides TCP and UDP connectivity.
