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

      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "v3Tests", logState: logState) {
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
  
  private let bandSettingStatus_1 = "band 999 band_name=221 acc_txreq_enable=1 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=0 tx2_enabled=1 tx3_enabled=0"
  private let bandSettingRemove_1 = "band 999 removed"
  func testBandSettingParse_1() {
    let name = "BandSetting"
    let id = bandSettingStatus_1.components(separatedBy: " ")[1].objectId!

    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      sleep(1)
      
      // remove (if present)
      radio!.bandSettings["999".objectId!] = nil
      
      BandSetting.parseStatus(radio!, bandSettingStatus_1.keyValuesArray(), true)

      if let object = radio!.bandSettings[id] {
        
        if showInfoMessages { Swift.print("***** \(name) object created") }
        
        XCTAssertEqual(object.bandName, "221")
        XCTAssertEqual(object.accTxReqEnabled, true)
        XCTAssertEqual(object.rcaTxReqEnabled, false)
        XCTAssertEqual(object.accTxEnabled, true)
        XCTAssertEqual(object.tx1Enabled, false)
        XCTAssertEqual(object.tx2Enabled, true)
        XCTAssertEqual(object.tx3Enabled, false)
        
        if showInfoMessages { Swift.print("***** \(name) object parameters verified") }
        
        BandSetting.parseStatus(radio!, bandSettingRemove_1.keyValuesArray(), false)
        
        if radio!.bandSettings[id] == nil {
          
          if showInfoMessages { Swift.print("***** \(name) object removed") }

        } else {
          XCTFail("***** \(name) object NOT removed *****")
        }
      } else {
        XCTFail("***** \(name) object NOT created *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  private var bandSettingStatus_2 = "band 998 band_name=WWV rfpower=50 tunepower=10 hwalc_enabled=1 inhibit=0"
  private let bandSettingRemove_2 = "band 998 removed"
  func testBandSetting2Parse() {
    let name = "BandSetting"
    let id = bandSettingStatus_2.components(separatedBy: " ")[1].objectId!

    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      // remove (if present)
      radio!.bandSettings["2".objectId!] = nil
      
      BandSetting.parseStatus(radio!, bandSettingStatus_2.keyValuesArray(), true)

      if let object = radio!.bandSettings[id] {
        
        if showInfoMessages { Swift.print("***** \(name) object created") }
        
        XCTAssertEqual(object.bandName, "WWV")
        XCTAssertEqual(object.rfPower, 50)
        XCTAssertEqual(object.tunePower, 10)
        XCTAssertEqual(object.hwAlcEnabled, true)
        XCTAssertEqual(object.inhibit, false)
        
        if showInfoMessages { Swift.print("***** \(name) object parameters verified") }
        
        BandSetting.parseStatus(radio!, bandSettingRemove_2.keyValuesArray(), false)
        
        if radio!.bandSettings[id] == nil {
          
          if showInfoMessages { Swift.print("***** \(name) object removed") }

        } else {
          XCTFail("***** \(name) object NOT removed *****")
        }
      }else {
        XCTFail("***** \(name) object NOT created *****")
      }
    }  else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  func testBandSetting() {
    let name = "BandSetting"
    
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
    
    Swift.print("\n***** Please Wait, this test takes longer than others *****\n")
    
    let radio = discoverRadio(logState: .limited(to: "BandSetting.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      for (id, object) in radio!.bandSettings {
        
        if showInfoMessages { Swift.print("Saving band id = \(id), name = \(object.bandName)") }
        
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
      
      if showInfoMessages { Swift.print("***** \(name) parameters saved") }
      
      for (_, object) in radio!.bandSettings {
        
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

        if showInfoMessages { Swift.print("***** \(name) \(object.bandName) parameters modified") }
        
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
        
        if showInfoMessages { Swift.print("***** \(name) \(object.bandName) parameters verified") }
        
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

        if showInfoMessages { Swift.print("***** \(name) \(object.bandName) parameters modified") }
        
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
        
        if showInfoMessages { Swift.print("***** \(name) \(object.bandName) parameters verified") }
      }
      for (_, entry) in tempArray.enumerated() {
        let id = entry.id

        if showInfoMessages { Swift.print("Restoring band id = \(id), name = \(entry.bandName)") }
                
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
      
      if showInfoMessages { Swift.print("***** Previous \(name) parameters restored") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxIqStream
  
  // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>
  private var daxIqStreamStatus = "0x20000000 type=dax_iq daxiq_channel=3 pan=0x40000000 ip=10.0.1.107 daxiq_rate=48000"
  func testDaxIqParse() {
    let name = "DaxIqStream"
    let id = daxIqStreamStatus.components(separatedBy: " ").first!.streamId!
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxIqStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxIqStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxIqStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Previous \(name) object(s) removed") }
        
        DaxIqStream.parseStatus(radio!, daxIqStreamStatus.keyValuesArray(), true)
        
        if radio!.daxIqStreams.count == 1 {
          if let object = radio!.daxIqStreams[id] {
            
            if showInfoMessages { Swift.print("***** \(name) object created") }
            
            XCTAssertEqual(object.id, id)
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
            XCTAssertEqual(object.channel, 3)
            XCTAssertEqual(object.ip, "10.0.1.107")
            XCTAssertEqual(object.isActive, false)
            XCTAssertEqual(object.pan, "0x40000000".streamId)
            XCTAssertEqual(object.rate, 48_000)
            
            if showInfoMessages { Swift.print("***** \(name) object properties verified") }
            
            object.ip = "11.1.1.108"
            object.rate = 96_000
            
            if showInfoMessages { Swift.print("***** \(name) object properties modified") }
            
            XCTAssertEqual(object.id, id)
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
            XCTAssertEqual(object.ip, "11.1.1.108")
            XCTAssertEqual(object.rate, 96_000)
            
            if showInfoMessages { Swift.print("***** Modified \(name) object properties verified") }
            
          } else {
            XCTFail("***** \(name) object NOT found *****")
          }
        } else {
          XCTFail("***** \(name) object NOT created *****")
        }
      } else {
        XCTFail("***** Existing \(name) object(s) NOT removed *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  func testDaxIqStream() {
    let name = "DaxIqStream"
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      radio!.iqStreams.forEach { $0.value.remove() }
      sleep(1)
      if radio!.daxIqStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Previous \(name) object(s) removed") }
        
        // get new
        radio!.requestDaxIqStream("3")
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st \(name) object requested") }
        
        // verify added
        if radio!.daxIqStreams.count == 1 {
          
          if let object = radio!.daxIqStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(name) object created") }
            
            // save params
            let clientHandle  = object.clientHandle
            let channel       = object.channel
            let ip            = object.ip
            let isActive      = object.isActive
            let pan           = object.pan
            let rate          = object.rate
            
            if showInfoMessages { Swift.print("***** 1st \(name) object parameters saved") }
            
            // remove all
            radio!.daxIqStreams.forEach { $0.value.remove() }
            sleep(1)
            if radio!.daxIqStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(name) object removed") }
              
              // get new
              radio!.requestDaxIqStream("3")
              sleep(1)
              
              if showInfoMessages { Swift.print("***** 2nd \(name) object requested") }
              
              // verify added
              if radio!.daxIqStreams.count == 1 {
                if let object = radio!.daxIqStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object created") }
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.channel, channel)
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.isActive, isActive)
                  XCTAssertEqual(object.pan, pan)
                  XCTAssertEqual(object.rate, rate)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object parameters verified") }
                  
                } else {
                  XCTFail("***** 2nd \(name) object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd \(name) object NOT created *****")
              }
            } else {
              XCTFail("***** 1st \(name) object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st \(name) object  NOT found *****")
          }
        } else {
          XCTFail("***** 1st \(name) object NOT added *****")
        }
      } else {
        XCTFail("***** Previous \(name) object(s) NOT removed *****")
      }
      // remove
      radio!.daxIqStreams.forEach { $0.value.remove() }
      
      if showInfoMessages { Swift.print("***** \(name) object(s) removed") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream
  
  // Format:  <streamId, > <"type", "dax_mic"> <"client_handle", handle> <"ip", ipAddress>
  private var daxMicAudioStreamStatus = "0x04000008 type=dax_mic ip=192.168.1.162"
  
  func testDaxMicAudioStreamParse() {
    let name = "DaxMicAudioStream"
    let id = daxMicAudioStreamStatus.components(separatedBy: " ").first!.streamId!

    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxMicAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxMicAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Existing \(name) object(s) removed") }
        
        DaxMicAudioStream.parseStatus(radio!, Array(daxMicAudioStreamStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxMicAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(name) object created") }
          
          XCTAssertEqual(object.ip, "192.168.1.162")
          
          if showInfoMessages { Swift.print("***** \(name) object properties verified") }
          
          object.ip = "12.2.3.218"
          
          if showInfoMessages { Swift.print("***** \(name) object properties modified") }
          
          XCTAssertEqual(object.id, id)
          XCTAssertEqual(object.ip, "12.2.3.218")
          
          if showInfoMessages { Swift.print("***** Modified \(name) object properties verified") }
          
        } else {
          XCTFail("***** \(name) object NOT created *****")
        }
      } else {
        XCTFail("***** Existing \(name) object(s) *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testDaxMicAudioStream() {
    let name = "DaxMicAudioStream"
    var clientHandle : Handle = 0
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxMicAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Previous \(name) object(s) removed") }
        
        // ask for new
        radio!.requestDaxMicAudioStream()
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st \(name) object requested") }
        
        // verify added
        if radio!.daxMicAudioStreams.count == 1 {
          
          if let object = radio!.daxMicAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(name) Object created") }
            
            // save params
            let id = object.id
            clientHandle = object.clientHandle
            
            if showInfoMessages { Swift.print("***** \(name) object parameters saved") }
            
            // remove it
            radio!.daxMicAudioStreams[id]!.remove() }
          sleep(1)
          if radio!.daxMicAudioStreams.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st \(name) object removed") }
            
            // ask new
            radio!.requestDaxMicAudioStream()
            sleep(1)
            
            if showInfoMessages { Swift.print("***** 2nd \(name) object requested") }
            
            // verify added
            if radio!.daxMicAudioStreams.count == 1 {
              if let object = radio!.daxMicAudioStreams.first?.value {
                
                if showInfoMessages { Swift.print("***** 2nd \(name) object created") }
                
                let id = object.id
                
                // check params
                XCTAssertEqual(object.clientHandle, clientHandle)
                
                if showInfoMessages { Swift.print("***** 2nd \(name) object parameters verified") }
                
                // remove it
                radio!.daxMicAudioStreams[id]!.remove()
                sleep(1)
                if radio!.daxMicAudioStreams[id] == nil {
                  if showInfoMessages { Swift.print("***** \(name) object removed") }
                } else {
                  Swift.print("***** \(name) object NOT removed")
                }
                
              } else {
               XCTFail("***** 2nd \(name) object NOT found *****")
              }
            } else {
              XCTFail("***** 2nd \(name) object NOT added *****")
            }
          } else {
            XCTFail("***** 1st \(name) object NOT removed *****")
          }
        } else {
          XCTFail("***** 1st \(name) object NOT found *****")
        }
      } else {
        XCTFail("***** 1st \(name) object NOT added *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxRxAudioStream
  
  // Format:  <streamId, > <"type", "dax_rx"> <"dax_channel", channel> <"slice", sliceLetter>  <"client_handle", handle> <"ip", ipAddress
  private var daxRxAudioStreamStatus = "0x04000008 type=dax_rx dax_channel=2 slice=A ip=192.168.1.162"
  
  func testDaxRxAudioParse() {
    let name = "DaxRxAudioStream"
    let id = daxRxAudioStreamStatus.components(separatedBy: " ").first!.streamId!

    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxRxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxRxAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxRxAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Previous \(name) object(s) removed") }
        
        DaxRxAudioStream.parseStatus(radio!, Array(daxRxAudioStreamStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxRxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(name) object created") }
          
          XCTAssertEqual(object.daxChannel, 2)
          XCTAssertEqual(object.ip, "192.168.1.162")
          XCTAssertEqual(object.slice, nil)
          
          if showInfoMessages { Swift.print("***** \(name) object properties verified") }
          
          object.daxChannel = 4
          object.ip = "12.2.3.218"
          object.slice = radio!.slices["0".objectId!]
          
          if showInfoMessages { Swift.print("***** \(name) object properties modified") }
          
          XCTAssertEqual(object.id, id)
          XCTAssertEqual(object.daxChannel, 4)
          XCTAssertEqual(object.ip, "12.2.3.218")
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
          
          if showInfoMessages { Swift.print("***** Modified \(name) object properties verified") }
          
        } else {
          XCTFail("***** \(name) object NOT created *****")
        }
      } else {
        XCTFail("***** \(name) object NOT removed *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testDaxRxAudio() {
    let name = "DaxRxAudioStream"

    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      radio!.daxRxAudioStreams.forEach { $0.value.remove() }
      sleep(1)

      if radio!.daxRxAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Previous \(name) object(s) removed") }
        
        // ask for new
        radio!.requestDaxRxAudioStream("2")
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st \(name) object requested") }
        
        // verify added
        if radio!.daxRxAudioStreams.count == 1 {
          
          if let object = radio!.daxRxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(name) object created") }
            
            let id = object.id

            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let slice = object.slice
            
            if showInfoMessages { Swift.print("***** 1st \(name) object parameters saved") }
            
            // remove it
            radio!.daxRxAudioStreams[id]!.remove()
            sleep(1)
            if radio!.daxRxAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(name) object removed") }
              
              // ask new
              radio!.requestDaxRxAudioStream( "2")
              sleep(1)
              
              if showInfoMessages { Swift.print("***** 2nd \(name) object requested") }
              
              // verify added
              if radio!.daxRxAudioStreams.count == 1 {
                if let object = radio!.daxRxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object created") }
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, daxChannel)
                  XCTAssertEqual(object.slice, slice)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object parameters verified") }
                  
                } else {
                  XCTFail("***** 2nd \(name) object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd \(name) object NOT added *****")
              }
            } else {
              XCTFail("***** 1st \(name) object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st \(name) object NOT found *****")
          }
        } else {
          XCTFail("***** 1st \(name) object NOT added *****")
        }
      } else {
        XCTFail("***** Previous \(name) object(s) NOT removed *****")
      }
      // remove
      radio!.daxRxAudioStreams.forEach { $0.value.remove() }
      
      if showInfoMessages { Swift.print("***** \(name) object(s) removed") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxTxAudioStream
  
  // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"tx", isTransmitChannel>
  private var daxTxAudioStreamStatus = "0x0400000A type=dax_tx tx=1"
  
  func testDaxTxAudioParse() {
    let name = "DaxTxAudioStream"
    let id = daxTxAudioStreamStatus.components(separatedBy: " ").first!.streamId!

    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      daxTxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.daxTxAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.daxTxAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Existing \(name) objects removed") }
        
        DaxTxAudioStream.parseStatus(radio!, Array(daxTxAudioStreamStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.daxTxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(name) object created") }
          
          XCTAssertEqual(object.isTransmitChannel, true)
          
          if showInfoMessages { Swift.print("***** \(name) object properties verified") }
          
          object.isTransmitChannel = false
          
          if showInfoMessages { Swift.print("***** \(name) object properties modified") }
          
          XCTAssertEqual(object.isTransmitChannel, false)
          
          if showInfoMessages { Swift.print("***** Modified \(name) object properties verified") }
          
        } else {
          XCTFail("***** \(name) object NOT created *****")
        }
      } else {
        XCTFail("***** Existing \(name) object(s) NOT removed *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testDaxTxAudio() {
    let name = "DaxTxAudioStream"
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      for (_, object) in radio!.daxTxAudioStreams { object.remove() }
      sleep(1)
      if radio!.daxTxAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Existing \(name) objects removed") }
        
        // get new
        radio!.requestDaxTxAudioStream()
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st \(name) object requested") }
        
        // verify added
        if radio!.daxTxAudioStreams.count == 1 {
          
          if let object = radio!.daxTxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(name) object created") }
            
            // save params
            let clientHandle = object.clientHandle
            let isTransmitChannel = object.isTransmitChannel
            
            if showInfoMessages { Swift.print("***** 1st \(name) object parameters saved") }
            
            // remove all
            for (_, object) in radio!.daxTxAudioStreams { object.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(name) object removed") }
              
              // get new
              radio!.requestDaxTxAudioStream()
              sleep(1)
              
              if showInfoMessages { Swift.print("***** 2nd \(name) object requested") }
              
              // verify added
              if radio!.daxTxAudioStreams.count == 1 {
                if let object = radio!.daxTxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object created") }
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.isTransmitChannel, isTransmitChannel)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object parameters verified") }
                  
                } else {
                  XCTFail("***** 2nd \(name) object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd \(name) object NOT added *****")
              }
            } else {
              XCTFail("***** 1st \(name) object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st \(name) object NOT found *****")
          }
        } else {
          XCTFail("***** 1st \(name) object NOT added *****")
        }
      } else {
        XCTFail("***** Previous \(name) object(s) NOT removed *****")
      }
      // remove any DaxTxAudioStream
      for (_, object) in radio!.daxTxAudioStreams { object.remove() }
      
      if showInfoMessages { Swift.print("***** \(name) object(s) removed") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteRxAudioStream
  
  private var remoteRxAudioStreamStatus = "0x04000008 type=remote_audio_rx compression=NONE ip=192.168.1.162"
  func testRemoteRxAudioStreamParse() {
    let name = "RemoteRxAudioStream"
    let id = remoteRxAudioStreamStatus.components(separatedBy: " ").first!.streamId!
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      remoteRxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      // remove all
      radio!.remoteRxAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.remoteRxAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Existing \(name) object(s) removed") }
        
        RemoteRxAudioStream.parseStatus(radio!, Array(remoteRxAudioStreamStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.remoteRxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(name) object created") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.compression, "none")
          XCTAssertEqual(object.ip, "192.168.1.162")
          
          if showInfoMessages { Swift.print("***** \(name) object properties verified") }
          
          object.compression = "NONE"
          object.ip = "193.169.2.163"
          
          if showInfoMessages { Swift.print("***** \(name) object properties modified") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.compression, "NONE")
          XCTAssertEqual(object.ip, "193.169.2.163")
          
          if showInfoMessages { Swift.print("***** Modified \(name) object properties verified") }
          
        } else {
          XCTFail("***** \(name) object NOT created *****")
        }
      } else {
        XCTFail("***** Existing \(name) object(s) NOT removed *****")
      }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  func testRemoteRxAudioStream() {
    let name = "RemoteRxAudioStream"
        
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      radio!.remoteRxAudioStreams.forEach { $0.value.remove() }
      sleep(1)
      
      if radio!.remoteRxAudioStreams.count == 0 {
        
        if showInfoMessages { Swift.print("***** Previous \(name) object(s) removed") }
        
        // ask for new
        radio!.requestRemoteRxAudioStream()
        sleep(1)
        
        if showInfoMessages { Swift.print("***** 1st \(name) object requested") }
        
        if radio!.remoteRxAudioStreams.count == 1 {
          
          if let object = radio!.remoteRxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(name) object created") }
            
            let id = object.id
            
            let clientHandle = object.clientHandle
            let compression = object.compression
            let ip = object.ip
            
            if showInfoMessages { Swift.print("***** 1st \(name) object parameters saved") }
            
            radio!.remoteRxAudioStreams[id]!.remove()
            sleep(1)
            if radio!.remoteRxAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(name) object removed") }
              
              radio!.requestRemoteRxAudioStream()
              sleep(1)
              
              if showInfoMessages { Swift.print("***** 2nd \(name) object requested") }
              
              if radio!.remoteRxAudioStreams.count == 1 {
                if let object = radio!.remoteRxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object created") }
                  
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.compression, compression)
                  XCTAssertEqual(object.ip, ip)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(name) object parameters verified") }
                  
                } else {
                  XCTFail("***** 2nd \(name) object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd \(name) object NOT added *****")
              }
            } else {
              XCTFail("***** 1st \(name) object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st \(name) object NOT found *****")
          }
        } else {
          XCTFail("***** 1st \(name) object NOT added *****")
        }
      } else {
        XCTFail("***** Previous \(name) object(s) NOT removed *****")
      }
      // remove
      radio!.daxRxAudioStreams.forEach { $0.value.remove() }
      
      if showInfoMessages { Swift.print("***** \(name) object(s) removed") }
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - RemoteTxAudioStream
  
  private var remoteTxAudioStreamStatus = "0x84000000 type=remote_audio_tx compression=OPUS ip=192.168.1.162"
  func testRemoteTxParseAudioStream() {
      let name = "RemoteTxAudioStream"
      let id = remoteTxAudioStreamStatus.components(separatedBy: " ").first!.streamId!

      Swift.print("\n***** \(#function), " + requiredVersion)
      
      let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
      guard radio != nil else { return }
      
      if radio!.version.isV3 {
        
        remoteTxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
        
        // remove all
        radio!.remoteTxAudioStreams.forEach( {$0.value.remove() } )
        sleep(1)
        if radio!.remoteTxAudioStreams.count == 0 {
          
          if showInfoMessages { Swift.print("***** Existing \(name) object(s) removed") }
          
          RemoteTxAudioStream.parseStatus(radio!, Array(remoteTxAudioStreamStatus.keyValuesArray()), true)
          sleep(1)
          
          if let object = radio!.remoteTxAudioStreams[id] {
            
            if showInfoMessages { Swift.print("***** \(name) object created") }
            
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
            XCTAssertEqual(object.compression, "opus")
            XCTAssertEqual(object.ip, "192.168.1.162")

            if showInfoMessages { Swift.print("***** \(name) object properties verified") }
            
            object.compression = "NONE"
            object.ip = "193.169.2.163"

            if showInfoMessages { Swift.print("***** \(name) object properties modified") }
            
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
            XCTAssertEqual(object.compression, "NONE")
            XCTAssertEqual(object.ip, "193.169.2.163")

            if showInfoMessages { Swift.print("***** Modified \(name) object properties verified") }
            
          } else {
            XCTFail("***** \(name) object NOT created *****")
          }
        } else {
          XCTFail("***** Existing \(name) object(s) NOT removed *****")
        }
        
      } else {
        Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
      }
      disconnect()
    }

  func testRemoteTxAudioStream() {
    let name = "RemoteTxAudioStream"

      Swift.print("\n***** \(#function), " + requiredVersion)
      
      let radio = discoverRadio(logState: .limited(to: "\(name).swift"))
      guard radio != nil else { return }
      
      if radio!.version.isV3 {
        
        radio!.remoteTxAudioStreams.forEach { $0.value.remove() }
        sleep(1)
        if radio!.remoteTxAudioStreams.count == 0 {
          
          if showInfoMessages { Swift.print("***** Existing \(name) object(s) removed") }
          
          radio!.requestRemoteTxAudioStream()
          sleep(1)
          
          if showInfoMessages { Swift.print("***** 1st \(name) object requested") }
          
          if radio!.remoteTxAudioStreams.count == 1 {
            
            if let object = radio!.remoteTxAudioStreams.first?.value {
              
              if showInfoMessages { Swift.print("***** 1st \(name) object created") }
              
              let clientHandle = object.clientHandle
              let compression = object.compression
              let ip = object.ip

              if showInfoMessages { Swift.print("***** 1st \(name) object parameters saved") }
              
              radio!.remoteTxAudioStreams.forEach { $0.value.remove() }
              sleep(1)
              if radio!.remoteTxAudioStreams.count == 0 {
                
                if showInfoMessages { Swift.print("***** 1st \(name) object removed") }
                
                radio!.requestRemoteTxAudioStream()
                sleep(1)
                
                if showInfoMessages { Swift.print("***** 2nd \(name) object requested") }
                
                if radio!.remoteTxAudioStreams.count == 1 {
                  if let object = radio!.remoteTxAudioStreams.first?.value {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(name) object created") }
                    
                    XCTAssertEqual(object.clientHandle, clientHandle)
                    XCTAssertEqual(object.compression, compression)
                    XCTAssertEqual(object.ip, ip)
                    
                    if showInfoMessages { Swift.print("***** 2nd \(name) object parameters verified") }
                    
                  } else {
                    XCTFail("***** 2nd \(name) object NOT found *****")
                  }
                } else {
                  XCTFail("***** 2nd \(name) object NOT added *****")
                }
              } else {
                XCTFail("***** 1st \(name) object NOT removed *****")
              }
            } else {
              XCTFail("***** 1st \(name) object NOT found *****")
            }
          } else {
            XCTFail("***** 1st \(name) object NOT added *****")
          }
        } else {
          XCTFail("***** Previous \(name) object(s) NOT removed *****")
        }
        // remove all
        radio!.remoteTxAudioStreams.forEach { $0.value.remove() }
        
        if showInfoMessages { Swift.print("***** \(name) object(s) removed") }
        
      } else {
        Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
      }
      disconnect()
    }
}
