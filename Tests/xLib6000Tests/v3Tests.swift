//
//  v3Tests.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class v3Tests: XCTestCase {
  let requiredVersion   = "v3"
  let showInfoMessages  = false
  let minPause          : UInt32 = 30_000

  // Helper functions
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("***** Radio found (v\(discovery.discoveredRadios[0].firmwareVersion))")

      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "AudioTests", logState: logState) {
        sleep(1)
        
        Swift.print("***** Connected")
        
        return Api.sharedInstance.radio
      } else {
        XCTFail("***** Failed to connect to Radio\n")
        return nil
      }
    } else {
      XCTFail("***** No Radio(s) found\n")
      return nil
    }
  }
  
  func disconnect() {
    Api.sharedInstance.disconnect()
    
    Swift.print("***** Disconnected\n")
  }

  // ------------------------------------------------------------------------------
  // MARK: - BandSetting
  
  private let bandSettingStatus_1 = "band 1 band_name=21 acc_txreq_enable=1 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=0 tx2_enabled=1 tx3_enabled=0"
  private let bandSettingRemove_1 = "band 1 removed"
  func testBandSettingParse_1() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "BandSetting.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      // remove (if present)
      radio!.bandSettings["1".objectId!] = nil
      
      BandSetting.parseStatus(radio!, bandSettingStatus_1.keyValuesArray(), true)

      if let object = radio!.bandSettings["1".objectId!] {
        
        if showInfoMessages { Swift.print("***** BAND SETTING object created") }
        
        XCTAssertEqual(object.bandName, "21")
        XCTAssertEqual(object.accTxReqEnabled, true)
        XCTAssertEqual(object.rcaTxReqEnabled, false)
        XCTAssertEqual(object.accTxEnabled, true)
        XCTAssertEqual(object.tx1Enabled, false)
        XCTAssertEqual(object.tx2Enabled, true)
        XCTAssertEqual(object.tx3Enabled, false)
        
        if showInfoMessages { Swift.print("***** BAND SETTING object parameters verified") }
        
        BandSetting.parseStatus(radio!, bandSettingRemove_1.keyValuesArray(), false)
        
        if radio!.bandSettings["1".objectId!] == nil {
          
          if showInfoMessages { Swift.print("***** BAND SETTING object removed") }

        } else {
          XCTFail("***** BAND SETTING object NOT removed *****")
        }
      } else {
        XCTFail("***** BAND SETTING object NOT created *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  private var bandSettingStatus_2 = "band 2 band_name=WWV rfpower=50 tunepower=10 hwalc_enabled=1 inhibit=0"
  private let bandSettingRemove_2 = "band 2 removed"
  func testBandSetting2Parse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "BandSetting.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      // remove (if present)
      radio!.bandSettings["2".objectId!] = nil
      
      BandSetting.parseStatus(radio!, bandSettingStatus_2.keyValuesArray(), true)

      if let object = radio!.bandSettings["2".objectId!] {
        
        if showInfoMessages { Swift.print("***** BAND SETTING object created") }
        
        XCTAssertEqual(object.bandName, "WWV")
        XCTAssertEqual(object.rfPower, 50)
        XCTAssertEqual(object.tunePower, 10)
        XCTAssertEqual(object.hwAlcEnabled, true)
        XCTAssertEqual(object.inhibit, false)
        
        if showInfoMessages { Swift.print("***** BAND SETTING object parameters verified") }
        
        BandSetting.parseStatus(radio!, bandSettingRemove_2.keyValuesArray(), false)
        
        if radio!.bandSettings["2".objectId!] == nil {
          
          if showInfoMessages { Swift.print("***** BAND SETTING object removed") }

        } else {
          XCTFail("***** BAND SETTING object NOT removed *****")
        }
      }else {
        XCTFail("***** BAND SETTING object NOT created *****")
      }
    }  else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  func testBandSetting() {
    
    struct Temp {
      var id              : ObjectId
      var bandName        : String
      var accTxEnabled    : Bool
      var accTxReqEnabled : Bool
      var hwAlcEnabled    : Bool
      var inhibit         : Bool
      var rcaTxReqEnabled : Bool
      var rfPower         : Int
      var tunePower       : Int
      var tx1Enabled      : Bool
      var tx2Enabled      : Bool
      var tx3Enabled      : Bool
    }
    var tempArray = [Temp]()
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "BandSetting.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      for (id, object) in radio!.bandSettings {
        
        Swift.print("Saving band id = \(id), name = \(object.bandName)")
        
        tempArray.append( Temp(id: object.id,
                               bandName: object.bandName,
                               accTxEnabled: object.accTxEnabled,
                               accTxReqEnabled: object.accTxReqEnabled,
                               hwAlcEnabled: object.hwAlcEnabled,
                               inhibit: object.inhibit,
                               rcaTxReqEnabled: object.rcaTxReqEnabled,
                               rfPower: object.rfPower,
                               tunePower: object.tunePower,
                               tx1Enabled: object.tx1Enabled,
                               tx2Enabled: object.tx2Enabled,
                               tx3Enabled: object.tx3Enabled
                              )
        )
      }
      
      if showInfoMessages { Swift.print("***** BAND SETTING parameters saved") }
      
      for (_, object) in radio!.bandSettings {
        let name = object.bandName
        
        object.accTxEnabled                = false
        usleep(minPause)
        object.accTxReqEnabled             = false
        usleep(minPause)
        object.hwAlcEnabled                = false
        usleep(minPause)
        object.inhibit                     = false
        usleep(minPause)
        object.rcaTxReqEnabled             = false
        usleep(minPause)
        object.rfPower                     = 0
        usleep(minPause)
        object.tunePower                   = 0
        usleep(minPause)
        object.tx1Enabled                  = false
        usleep(minPause)
        object.tx2Enabled                  = false
        usleep(minPause)
        object.tx3Enabled                  = false
        usleep(minPause)

        if showInfoMessages { Swift.print("***** BAND SETTING \(name) parameters modified") }
        
        XCTAssertEqual(object.accTxEnabled, false, "accTxEnabled")
        XCTAssertEqual(object.accTxReqEnabled, false, "accTxReqEnabled")
        XCTAssertEqual(object.hwAlcEnabled, false, "hwAlcEnabled")
        XCTAssertEqual(object.inhibit, false, "inhibit")
        XCTAssertEqual(object.rcaTxReqEnabled, false, "rcaTxReqEnabled")
        XCTAssertEqual(object.rfPower, 0, "rfPower")
        XCTAssertEqual(object.tunePower, 0, "tunePower")
        XCTAssertEqual(object.tx1Enabled, false, "tx1Enabled")
        XCTAssertEqual(object.tx2Enabled, false, "tx2Enabled")
        XCTAssertEqual(object.tx3Enabled, false, "tx3Enabled")
        
        if showInfoMessages { Swift.print("***** BAND SETTING \(name) parameters verified") }
        
        object.accTxEnabled                = true
        usleep(minPause)
        object.accTxReqEnabled             = true
        usleep(minPause)
        object.hwAlcEnabled                = true
        usleep(minPause)
        object.inhibit                     = true
        usleep(minPause)
        object.rcaTxReqEnabled             = true
        usleep(minPause)
        object.rfPower                     = 50
        usleep(minPause)
        object.tunePower                   = 75
        usleep(minPause)
        object.tx1Enabled                  = true
        usleep(minPause)
        object.tx2Enabled                  = true
        usleep(minPause)
        object.tx3Enabled                  = true
        usleep(minPause)

        if showInfoMessages { Swift.print("***** BAND SETTING \(name) parameters modified") }
        
        XCTAssertEqual(object.accTxEnabled, true, "accTxEnabled")
        XCTAssertEqual(object.accTxReqEnabled, true, "accTxReqEnabled")
        XCTAssertEqual(object.hwAlcEnabled, true, "hwAlcEnabled")
        XCTAssertEqual(object.inhibit, true, "inhibit")
        XCTAssertEqual(object.rcaTxReqEnabled, true, "rcaTxReqEnabled")
        XCTAssertEqual(object.rfPower, 50, "rfPower")
        XCTAssertEqual(object.tunePower, 75, "tunePower")
        XCTAssertEqual(object.tx1Enabled, true, "tx1Enabled")
        XCTAssertEqual(object.tx2Enabled, true, "tx2Enabled")
        XCTAssertEqual(object.tx3Enabled, true, "tx3Enabled")
        
        if showInfoMessages { Swift.print("***** BAND SETTING \(name) parameters verified") }
      }
      for (_, entry) in tempArray.enumerated() {
        let id = entry.id

        Swift.print("Restoring band id = \(id), name = \(entry.bandName)")
                
        radio!.bandSettings[id]!.accTxEnabled                = entry.accTxEnabled
        usleep(minPause)
        radio!.bandSettings[id]!.accTxReqEnabled             = entry.accTxReqEnabled
        usleep(minPause)
        radio!.bandSettings[id]!.hwAlcEnabled                = entry.hwAlcEnabled
        usleep(minPause)
        radio!.bandSettings[id]!.inhibit                     = entry.inhibit
        usleep(minPause)
        radio!.bandSettings[id]!.rcaTxReqEnabled             = entry.rcaTxReqEnabled
        usleep(minPause)
        radio!.bandSettings[id]!.rfPower                     = entry.rfPower
        usleep(minPause)
        radio!.bandSettings[id]!.tunePower                   = entry.tunePower
        usleep(minPause)
        radio!.bandSettings[id]!.tx1Enabled                  = entry.tx1Enabled
        usleep(minPause)
        radio!.bandSettings[id]!.tx2Enabled                  = entry.tx2Enabled
        usleep(minPause)
        radio!.bandSettings[id]!.tx3Enabled                  = entry.tx3Enabled
        usleep(minPause)
      }
      
      if showInfoMessages { Swift.print("***** Previous BAND SETTING parameters restored") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxIqStream
  
  // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>
  private var daxIqStatus = "0x20000000 type=dax_iq daxiq_channel=3 pan=0x40000000 ip=10.0.1.107 daxiq_rate=48"
  func testDaxIqParse() {
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxIqStream.swift"))
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
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testDaxIq() {
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "DaxIqStream.swift"))
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
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
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
        
        if showInfoMessages { Swift.print("***** Existing object(s) removed") }
        
        DaxMicAudioStream.parseStatus(radio!, Array(daxMicAudioStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxMicAudioStreams["0x04000008".streamId!] {
          
          if showInfoMessages { Swift.print("***** Object created") }
          
          XCTAssertEqual(object.ip, "192.168.1.162")
          
          if showInfoMessages { Swift.print("***** Properties verified") }
          
          object.ip = "12.2.3.218"
          
          if showInfoMessages { Swift.print("***** Properties modified") }
          
          XCTAssertEqual(object.id, "0x04000008".streamId)
          XCTAssertEqual(object.ip, "12.2.3.218")
          
          if showInfoMessages { Swift.print("***** Modified properties verified") }
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
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
        
        if showInfoMessages { Swift.print("***** Previous object(s) removed") }
        
        // ask for new
        radio!.requestDaxMicAudioStream()
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st object requested") }
        
        // verify added
        if radio!.daxMicAudioStreams.count == 1 {
          
          if let object = radio!.daxMicAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st Object created") }
            
            // save params
            let id = object.id
            clientHandle = object.clientHandle
            
            if showInfoMessages { Swift.print("***** Parameters saved") }
            
            // remove it
            radio!.daxMicAudioStreams[id]!.remove() }
          sleep(1)
          if radio!.daxMicAudioStreams.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st Object removed") }
            
            // ask new
            radio!.requestDaxMicAudioStream()
            sleep(1)
            
            if showInfoMessages { Swift.print("***** 2nd object requested") }
            
            // verify added
            if radio!.daxMicAudioStreams.count == 1 {
              if let object = radio!.daxMicAudioStreams.first?.value {
                
                if showInfoMessages { Swift.print("***** 2nd Object created") }
                
                let id = object.id
                
                // check params
                XCTAssertEqual(object.clientHandle, clientHandle)
                
                if showInfoMessages { Swift.print("***** Parameters verified") }
                
                // remove it
                radio!.daxMicAudioStreams[id]!.remove()
                sleep(1)
                if radio!.daxMicAudioStreams[id] == nil {
                  if showInfoMessages { Swift.print("***** Object removed") }
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
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
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
        
        if showInfoMessages { Swift.print("***** Previous object(s) removed") }
        
        DaxRxAudioStream.parseStatus(radio!, Array(daxRxAudioStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxRxAudioStreams["0x04000008".streamId!] {
          
          if showInfoMessages { Swift.print("***** Object created") }
          
          XCTAssertEqual(object.daxChannel, 2)
          XCTAssertEqual(object.ip, "192.168.1.162")
          XCTAssertEqual(object.slice, nil)
          
          if showInfoMessages { Swift.print("***** Properties verified") }
          
          object.daxChannel = 4
          object.ip = "12.2.3.218"
          object.slice = radio!.slices["0".objectId!]
          
          if showInfoMessages { Swift.print("***** Properties modified") }
          
          XCTAssertEqual(object.id, "0x04000008".streamId)
          XCTAssertEqual(object.daxChannel, 4)
          XCTAssertEqual(object.ip, "12.2.3.218")
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
          
          if showInfoMessages { Swift.print("***** Modified properties verified") }
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
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
        
        if showInfoMessages { Swift.print("***** Previous object(s) removed") }
        
        // ask for new
        radio!.requestDaxRxAudioStream( "2")
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st object requested") }
        
        // verify added
        if radio!.daxRxAudioStreams.count == 1 {
          
          if let object = radio!.daxRxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st Object created") }
            
            // save params
            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let slice = object.slice
            
            if showInfoMessages { Swift.print("***** Parameters saved") }
            
            // remove all
            for (_, object) in radio!.daxRxAudioStreams { object.remove() }
            sleep(1)
            if radio!.daxRxAudioStreams.count == 0 {
               }
              if showInfoMessages { Swift.print("***** 1st Object removed")
              
              // ask new
              radio!.requestDaxRxAudioStream( "2")
              sleep(1)
              
              if showInfoMessages { Swift.print("***** 2nd object requested") }
              
              // verify added
              if radio!.daxRxAudioStreams.count == 1 {
                if let object = radio!.daxRxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd Object created") }
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, daxChannel)
                  XCTAssertEqual(object.slice, slice)
                  
                  if showInfoMessages { Swift.print("***** Parameters verified") }
                  
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
      
      if showInfoMessages { Swift.print("***** Object(s) removed") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
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
        
        if showInfoMessages { Swift.print("***** Existing objects removed") }
        
        DaxTxAudioStream.parseStatus(radio!, Array(daxTxAudioStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxTxAudioStreams["0x0400000A".streamId!] {
          
          if showInfoMessages { Swift.print("***** Object created") }
          
          XCTAssertEqual(object.isTransmitChannel, true)
          
          if showInfoMessages { Swift.print("***** Properties verified") }
          
          object.isTransmitChannel = false
          
          if showInfoMessages { Swift.print("***** Properties modified") }
          
          XCTAssertEqual(object.isTransmitChannel, false)
          
          if showInfoMessages { Swift.print("***** Modified properties verified") }
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
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
        
        if showInfoMessages { Swift.print("***** Existing objects removed") }
        
        // get new
        radio!.requestDaxTxAudioStream()
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st object requested") }
        
        // verify added
        if radio!.daxTxAudioStreams.count == 1 {
          
          if let object = radio!.daxTxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st object created") }
            
            // save params
            let clientHandle = object.clientHandle
            let isTransmitChannel = object.isTransmitChannel
            
            if showInfoMessages { Swift.print("***** Parameters saved") }
            
            // remove all
            for (_, object) in radio!.daxTxAudioStreams { object.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st Object removed") }
              
              // get new
              radio!.requestDaxTxAudioStream()
              sleep(1)
              
              if showInfoMessages { Swift.print("***** 2nd object requested") }
              
              // verify added
              if radio!.daxTxAudioStreams.count == 1 {
                if let object = radio!.daxTxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd Object created") }
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.isTransmitChannel, isTransmitChannel)
                  
                  if showInfoMessages { Swift.print("***** Parameters verified") }
                  
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
      
      if showInfoMessages { Swift.print("***** Object(s) removed") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteRxAudioStream
  
  func testRemoteRxParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "RemoteRxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      XCTFail("NOT performed, --- FIX ME ---")

    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testRemoteRx() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "RemoteRxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      XCTFail("NOT performed, --- FIX ME ---")

    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteTxAudioStream
  
  func testRemoteTxParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "RemoteTxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      XCTFail("NOT performed, --- FIX ME ---")

    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testRemoteTx() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "RemoteTxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      XCTFail("NOT performed, --- FIX ME ---")

    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
}
