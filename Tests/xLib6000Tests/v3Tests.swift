//
//  v3Tests.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class v3Tests: XCTestCase {
  let requiredVersion = "v3"

  // Helper functions
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("\n***** Radio found (v\(discovery.discoveredRadios[0].firmwareVersion))")

      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "AudioTests", logState: logState) {
        sleep(1)
        
        Swift.print("***** Connected")
        
        return Api.sharedInstance.radio
      } else {
        XCTAssertTrue(false, "***** Failed to connect to Radio")
        return nil
      }
    } else {
      XCTAssertTrue(false, "***** No Radio(s) found")
      return nil
    }
  }
  
  func disconnect() {
    Api.sharedInstance.disconnect()
    
    Swift.print("***** Disconnected\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - BandSetting
  
  private var bandSettingStatus = "band 999 band_name=21 acc_txreq_enable=1 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=0 tx2_enabled=1 tx3_enabled=0"
  func testBandSettingParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "BandSetting.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      // remove (if present)
      radio!.bandSettings["999".objectId!] = nil
      
      BandSetting.parseStatus(radio!, bandSettingStatus.keyValuesArray(), true)

      if let bandSettingObject = radio!.bandSettings["999".objectId!] {
        // verify properties
        XCTAssertEqual(bandSettingObject.bandName, "21")
        XCTAssertEqual(bandSettingObject.accTxReqEnabled, true)
        XCTAssertEqual(bandSettingObject.rcaTxReqEnabled, false)
        XCTAssertEqual(bandSettingObject.accTxEnabled, true)
        XCTAssertEqual(bandSettingObject.tx1Enabled, false)
        XCTAssertEqual(bandSettingObject.tx2Enabled, true)
        XCTAssertEqual(bandSettingObject.tx3Enabled, false)

      } else {
        XCTFail("***** Failed to create BandSetting *****")
      }

    }  else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }

  func testBandSetting() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")

    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxIqStream
  
  // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>
  private var daxIqStatus = "0x20000000 type=dax_iq daxiq_channel=3 pan=0x40000000 ip=10.0.1.107 daxiq_rate=48"
  func testDaxIqParse() {
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxIqStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      DaxIqStream.parseStatus(radio!, daxIqStatus.keyValuesArray(), true)
      
      if radio!.daxIqStreams.count == 1 {
        let daxIqStreamObject = radio!.daxIqStreams.first!.value
        // verify properties
        XCTAssertEqual(daxIqStreamObject.id, "0x20000000".streamId!)
        XCTAssertEqual(daxIqStreamObject.clientHandle, Api.sharedInstance.connectionHandle!)
        XCTAssertEqual(daxIqStreamObject.channel, 3)
        XCTAssertEqual(daxIqStreamObject.ip, "10.0.1.107")
        XCTAssertEqual(daxIqStreamObject.isActive, false)
        XCTAssertEqual(daxIqStreamObject.pan, "0x40000000".streamId)
        XCTAssertEqual(daxIqStreamObject.rate, 48)
        
      } else {
        XCTFail("***** Failed to create object *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testDaxIq() {
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      for (_, daxIqStreamObject) in radio!.iqStreams { daxIqStreamObject.remove() }
      sleep(1)
      if radio!.daxIqStreams.count == 0 {
        
        // get new
        radio!.requestIqStream("3")
        sleep(1)
        
        // verify added
        if radio!.daxIqStreams.count == 1 {
          
          if let daxIqStreamObject = radio!.daxIqStreams.first?.value {
            
            // save params
            let clientHandle  = daxIqStreamObject.clientHandle
            let channel       = daxIqStreamObject.channel
            let ip            = daxIqStreamObject.ip
            let isActive      = daxIqStreamObject.isActive
            let pan           = daxIqStreamObject.pan
            let rate          = daxIqStreamObject.rate
            
            // remove all
            for (_, daxIqStreamObject) in radio!.daxIqStreams { daxIqStreamObject.remove() }
            sleep(1)
            if radio!.daxIqStreams.count == 0 {
              
              // get new
              radio!.requestDaxIqStream("3")
              sleep(1)
              
              // verify added
              if radio!.daxIqStreams.count == 1 {
                if let daxIqStreamObject = radio!.daxIqStreams.first?.value {
                  
                  // check params
                  XCTAssertEqual(daxIqStreamObject.clientHandle, clientHandle)
                  XCTAssertEqual(daxIqStreamObject.channel, channel)
                  XCTAssertEqual(daxIqStreamObject.ip, ip)
                  XCTAssertEqual(daxIqStreamObject.isActive, isActive)
                  XCTAssertEqual(daxIqStreamObject.pan, pan)
                  XCTAssertEqual(daxIqStreamObject.rate, rate)
                  
                  // remove it
                  daxIqStreamObject.remove()
                  sleep(1)
                  
                  if radio!.daxIqStreams.count != 0 {
                    XCTFail("***** DaxIqStream NOT removed *****")
                  }
                } else {
                  XCTFail("***** DaxIqStream 0 NOT found *****")
                }
              } else {
                XCTFail("***** DaxIqStream NOT added *****")
              }
            } else {
              XCTFail("***** DaxIqStream NOT removed *****")
            }
          } else {
            XCTFail("***** DaxIqStream 0 NOT found *****")
          }
        } else {
          XCTFail("***** DaxIqStream NOT added *****")
        }
      } else {
        XCTFail("***** DaxIqStream NOT removed *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream
  
  // Format:  <streamId, > <"type", "dax_mic"> <"client_handle", handle> <"ip", ipAddress>
  private var daxMicAudioStatus = "0x04000008 type=dax_mic ip=192.168.1.162"
  
  func testDaxMicParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxMicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxMicAudioStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxMicAudioStreams.count == 0 {
        
        Swift.print("***** Existing object(s) removed")
        
        DaxMicAudioStream.parseStatus(radio!, Array(daxMicAudioStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxMicAudioStreams["0x04000008".streamId!] {
          
          Swift.print("***** Object created")
          
          XCTAssertEqual(object.ip, "192.168.1.162")
          
          Swift.print("***** Properties verified")
          
          object.ip = "12.2.3.218"
          
          Swift.print("***** Properties modified")
          
          XCTAssertEqual(object.id, "0x04000008".streamId)
          XCTAssertEqual(object.ip, "12.2.3.218")
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testDaxMic() {
    var clientHandle : Handle = 0
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxMicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxMicAudioStreams.count == 0 {
        
        Swift.print("***** Previous object(s) removed")
        
        // ask for new
        radio!.requestDaxMicAudioStream()
        sleep(1)
        
        Swift.print("***** 1st object requested")
        
        // verify added
        if radio!.daxMicAudioStreams.count == 1 {
          
          if let object = radio!.daxMicAudioStreams.first?.value {
            
            Swift.print("***** 1st Object created")
            
            // save params
            let id = object.id
            clientHandle = object.clientHandle
            
            Swift.print("***** Parameters saved")
            
            // remove it
            radio!.daxMicAudioStreams[id]!.remove() }
          sleep(1)
          if radio!.daxMicAudioStreams.count == 0 {
            
            Swift.print("***** 1st Object removed")
            
            // ask new
            radio!.requestDaxMicAudioStream()
            sleep(1)
            
            Swift.print("***** 2nd object requested")
            
            // verify added
            if radio!.daxMicAudioStreams.count == 1 {
              if let object = radio!.daxMicAudioStreams.first?.value {
                
                Swift.print("***** 2nd Object created")
                
                let id = object.id
                
                // check params
                XCTAssertEqual(object.clientHandle, clientHandle)
                
                Swift.print("***** Parameters verified")
                
                // remove it
                radio!.daxMicAudioStreams[id]!.remove()
                sleep(1)
                if radio!.daxMicAudioStreams[id] == nil {
                  Swift.print("***** Object removed")
                } else {
                  Swift.print("ERROR: ***** Object NOT removed")
                }
                
              } else {
               XCTFail("***** 2nd Object NOT found *****")
              }
            } else {
              XCTFail("***** 2nd Object NOT added *****")
            }
          } else {
            XCTFail("***** 1st Object NOT removed *****")
          }
        } else {
          XCTFail("***** 1st Object NOT found *****")
        }
      } else {
        XCTFail("***** 1st Object NOT added *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxRxAudioStream
  
  // Format:  <streamId, > <"type", "dax_rx"> <"dax_channel", channel> <"slice", sliceLetter>  <"client_handle", handle> <"ip", ipAddress
  private var daxRxAudioStatus = "0x04000008 type=dax_rx dax_channel=2 slice=A ip=192.168.1.162"
  
  func testDaxRxAudioParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxRxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxRxAudioStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxRxAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxRxAudioStreams.count == 0 {
        
        Swift.print("***** Previous object(s) removed")
        
        DaxRxAudioStream.parseStatus(radio!, Array(daxRxAudioStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxRxAudioStreams["0x04000008".streamId!] {
          
          Swift.print("***** Object created")
          
          XCTAssertEqual(object.daxChannel, 2)
          XCTAssertEqual(object.ip, "192.168.1.162")
          XCTAssertEqual(object.slice, nil)
          
          Swift.print("***** Properties verified")
          
          object.daxChannel = 4
          object.ip = "12.2.3.218"
          object.slice = radio!.slices["0".objectId!]
          
          Swift.print("***** Properties modified")
          
          XCTAssertEqual(object.id, "0x04000008".streamId)
          XCTAssertEqual(object.daxChannel, 4)
          XCTAssertEqual(object.ip, "12.2.3.218")
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testDaxRxAudio() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxRxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      for (_, object) in radio!.daxRxAudioStreams { object.remove() }
      sleep(1)
      if radio!.daxRxAudioStreams.count == 0 {
        
        Swift.print("***** Previous object(s) removed")
        
        // ask for new
        radio!.requestDaxRxAudioStream( "2")
        sleep(1)
        
        Swift.print("***** 1st object requested")
        
        // verify added
        if radio!.daxRxAudioStreams.count == 1 {
          
          if let object = radio!.daxRxAudioStreams.first?.value {
            
            Swift.print("***** 1st Object created")
            
            // save params
            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let slice = object.slice
            
            Swift.print("***** Parameters saved")
            
            // remove all
            for (_, object) in radio!.daxRxAudioStreams { object.remove() }
            sleep(1)
            if radio!.daxRxAudioStreams.count == 0 {
              
              Swift.print("***** 1st Object removed")
              
              // ask new
              radio!.requestDaxRxAudioStream( "2")
              sleep(1)
              
              Swift.print("***** 2nd object requested")
              
              // verify added
              if radio!.daxRxAudioStreams.count == 1 {
                if let object = radio!.daxRxAudioStreams.first?.value {
                  
                  Swift.print("***** 2nd Object created")
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, daxChannel)
                  XCTAssertEqual(object.slice, slice)
                  
                  Swift.print("***** Parameters verified")
                  
                } else {
                  XCTFail("***** 2nd Object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd Object NOT added *****")
              }
            } else {
              XCTFail("***** 1st Object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st Object NOT found *****")
          }
        } else {
          XCTFail("***** 1st Object NOT added *****")
        }
      } else {
        XCTFail("***** Previous Object(s) NOT removed *****")
      }
      // remove
      for (_, object) in radio!.daxRxAudioStreams { object.remove() }
      
      Swift.print("***** Object(s) removed")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxTxAudioStream
  
  // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"tx", isTransmitChannel>
  private var daxTxAudioStatus = "0x0400000A type=dax_tx tx=1"
  
  func testDaxTxAudioParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxTxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxTxAudioStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxTxAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxTxAudioStreams.count == 0 {
        
        Swift.print("***** Existing objects removed")
        
        DaxTxAudioStream.parseStatus(radio!, Array(daxTxAudioStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxTxAudioStreams["0x0400000A".streamId!] {
          
          Swift.print("***** Object created")
          
          XCTAssertEqual(object.isTransmitChannel, true)
          
          Swift.print("***** Properties verified")
          
          object.isTransmitChannel = false
          
          Swift.print("***** Properties modified")
          
          XCTAssertEqual(object.isTransmitChannel, false)
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testDaxTxAudio() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxTxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      for (_, object) in radio!.daxTxAudioStreams { object.remove() }
      sleep(1)
      if radio!.daxTxAudioStreams.count == 0 {
        
        Swift.print("***** Existing objects removed")
        
        // get new
        radio!.requestDaxTxAudioStream()
        sleep(1)
        
        Swift.print("***** 1st object requested")
        
        // verify added
        if radio!.daxTxAudioStreams.count == 1 {
          
          if let object = radio!.daxTxAudioStreams.first?.value {
            
            Swift.print("***** 1st object created")
            
            // save params
            let clientHandle = object.clientHandle
            let isTransmitChannel = object.isTransmitChannel
            
            Swift.print("***** Parameters saved")
            
            // remove all
            for (_, object) in radio!.daxTxAudioStreams { object.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              Swift.print("***** 1st Object removed")
              
              // get new
              radio!.requestDaxTxAudioStream()
              sleep(1)
              
              Swift.print("***** 2nd object requested")
              
              // verify added
              if radio!.daxTxAudioStreams.count == 1 {
                if let object = radio!.daxTxAudioStreams.first?.value {
                  
                  Swift.print("***** 2nd Object created")
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.isTransmitChannel, isTransmitChannel)
                  
                  Swift.print("***** Parameters verified")
                  
                } else {
                  XCTFail("***** 2nd Object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd Object NOT added *****")
              }
            } else {
              XCTFail("***** 1st Object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st Object NOT found *****")
          }
        } else {
          XCTFail("***** 1st Object NOT added *****")
        }
      } else {
        XCTFail("***** Previous Object(s) NOT removed *****")
      }
      // remove any DaxTxAudioStream
      for (_, object) in radio!.daxTxAudioStreams { object.remove() }
      
      Swift.print("***** Object(s) removed")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteRxAudioStream
  
  func testRemoteRxParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  func testRemoteRx() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteTxAudioStream
  
  func testRemoteTxParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  func testRemoteTx() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
}
