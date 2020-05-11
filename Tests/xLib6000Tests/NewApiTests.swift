//
//  NewApiTests.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class NewApiTests: XCTestCase {
  let connectAsGui      = true
  let requiredVersion   = "v3 || v2 NewApi"
  let showInfoMessages  = true
  let minPause          : UInt32 = 30_000
  
  // Helper functions
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("***** Radio found: \(discovery.discoveredRadios[0].nickname) (v\(discovery.discoveredRadios[0].firmwareVersion)) @ \(discovery.discoveredRadios[0].publicIp)")
      
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], program: "v3Tests", isGui: connectAsGui, logState: logState) {
        sleep(2)
        
        Swift.print("***** Connected")
        
        return Api.sharedInstance.radio
      } else {
        XCTFail("----->>>>> Failed to connect to Radio <<<<<-----\n", file: #function)
        return nil
      }
    } else {
      XCTFail("----->>>>> No Radio(s) found <<<<<-----\n", file: #function)
      return nil
    }
  }
  
  func disconnect() {
    Api.sharedInstance.disconnect()
    
    Swift.print("***** Disconnected\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - BandSetting
  
  private let bandSettingStatus_1 = "999 band_name=221 acc_txreq_enable=1 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=0 tx2_enabled=1 tx3_enabled=0"
  private let bandSettingRemove_1 = "999 removed"
  func testBandSettingParse_1() {
    let type = "BandSetting"
    let id = bandSettingStatus_1.components(separatedBy: " ")[0].objectId!
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      sleep(2)
      
      // remove (if present)
      radio!.bandSettings[id] = nil
      
      if showInfoMessages { Swift.print("\n***** \(type) object requested") }
      
      BandSetting.parseStatus(radio!, bandSettingStatus_1.keyValuesArray(), true)
      
      if let object = radio!.bandSettings[id] {
        
        if showInfoMessages { Swift.print("***** \(type) object added\n") }
        
        XCTAssertEqual(object.bandName, "221", "bandName", file: #function)
        XCTAssertEqual(object.accTxReqEnabled, true, "accTxReqEnabled", file: #function)
        XCTAssertEqual(object.rcaTxReqEnabled, false, "rcaTxReqEnabled", file: #function)
        XCTAssertEqual(object.accTxEnabled, true, "accTxEnabled", file: #function)
        XCTAssertEqual(object.tx1Enabled, false, "tx1Enabled", file: #function)
        XCTAssertEqual(object.tx2Enabled, true, "tx2Enabled", file: #function)
        XCTAssertEqual(object.tx3Enabled, false, "tx3Enabled", file: #function)
        
        if showInfoMessages { Swift.print("***** \(type) object parameters verified") }
        
        if showInfoMessages { Swift.print("\n***** \(type) object removed") }
        
        BandSetting.parseStatus(radio!, bandSettingRemove_1.keyValuesArray(), false)
        
        if radio!.bandSettings[id] == nil {
          
          if showInfoMessages { Swift.print("***** \(type) object removal confirmed\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object removal FAILED <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> \(type) object NOT created <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  private var bandSettingStatus_2 = "998 band_name=WWV rfpower=50 tunepower=10 hwalc_enabled=1 inhibit=0"
  private let bandSettingRemove_2 = "998 removed"
  func testBandSettingParse_2() {
    let type = "BandSetting"
    let id = bandSettingStatus_2.components(separatedBy: " ")[0].objectId!
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      // remove (if present)
      radio!.bandSettings["2".objectId!] = nil
      
      if showInfoMessages { Swift.print("\n***** \(type) object requested") }
      
      BandSetting.parseStatus(radio!, bandSettingStatus_2.keyValuesArray(), true)
      
      if let object = radio!.bandSettings[id] {
        
        if showInfoMessages { Swift.print("***** \(type) object added\n") }
        
        XCTAssertEqual(object.bandName, "WWV", "bandName", file: #function)
        XCTAssertEqual(object.rfPower, 50, "rfPower", file: #function)
        XCTAssertEqual(object.tunePower, 10, "tunePower", file: #function)
        XCTAssertEqual(object.hwAlcEnabled, true, "hwAlcEnabled", file: #function)
        XCTAssertEqual(object.inhibit, false, "inhibit", file: #function)
        
        if showInfoMessages { Swift.print("***** \(type) object parameters verified") }
        
        if showInfoMessages { Swift.print("\n***** \(type) object removed") }
        
        BandSetting.parseStatus(radio!, bandSettingRemove_2.keyValuesArray(), false)
        
        if radio!.bandSettings[id] == nil {
          
          if showInfoMessages { Swift.print("***** \(type) object removal confirmed\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object removal FAILED <<<<<-----", file: #function)
        }
      }else {
        XCTFail("----->>>>> \(type) object NOT created <<<<<-----", file: #function)
      }
    }  else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testBandSetting() {
    let type = "BandSetting"
    
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
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    Swift.print("\n***** Please Wait, this test takes longer than others *****\n")
    
    let radio = discoverRadio(logState: .limited(to: ["BandSetting.swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      sleep(2)
      
      if showInfoMessages { Swift.print("\n***** Saving Existing \(type)s") }
      
      for (_, object) in radio!.bandSettings {
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
      
      if showInfoMessages { Swift.print("***** \(type) saved\n") }
      
      if showInfoMessages { Swift.print("***** Modifying \(type)s") }
      
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
        
        XCTAssertEqual(object.accTxEnabled, false, "accTxEnabled", file: #function)
        XCTAssertEqual(object.accTxReqEnabled, false, "accTxReqEnabled", file: #function)
        XCTAssertEqual(object.hwAlcEnabled, false, "hwAlcEnabled", file: #function)
        XCTAssertEqual(object.inhibit, false, "inhibit", file: #function)
        XCTAssertEqual(object.rcaTxReqEnabled, false, "rcaTxReqEnabled", file: #function)
        XCTAssertEqual(object.rfPower, 0, "rfPower", file: #function)
        XCTAssertEqual(object.tunePower, 0, "tunePower", file: #function)
        XCTAssertEqual(object.tx1Enabled, false, "tx1Enabled", file: #function)
        XCTAssertEqual(object.tx2Enabled, false, "tx2Enabled", file: #function)
        XCTAssertEqual(object.tx3Enabled, false, "tx3Enabled", file: #function)
        
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
        
        XCTAssertEqual(object.accTxEnabled, true, "accTxEnabled", file: #function)
        XCTAssertEqual(object.accTxReqEnabled, true, "accTxReqEnabled", file: #function)
        XCTAssertEqual(object.hwAlcEnabled, true, "hwAlcEnabled", file: #function)
        XCTAssertEqual(object.inhibit, true, "inhibit", file: #function)
        XCTAssertEqual(object.rcaTxReqEnabled, true, "rcaTxReqEnabled", file: #function)
        XCTAssertEqual(object.rfPower, 50, "rfPower", file: #function)
        XCTAssertEqual(object.tunePower, 75, "tunePower", file: #function)
        XCTAssertEqual(object.tx1Enabled, true, "tx1Enabled", file: #function)
        XCTAssertEqual(object.tx2Enabled, true, "tx2Enabled", file: #function)
        XCTAssertEqual(object.tx3Enabled, true, "tx3Enabled", file: #function)
      }
      
      if showInfoMessages { Swift.print("***** \(type) parameters modified & verified\n") }
      
      if showInfoMessages { Swift.print("***** Restoring previous \(type)s") }
      
      for (_, entry) in tempArray.enumerated() {
        let id = entry.id
        
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
      
      if showInfoMessages { Swift.print("***** Previous \(type)s restored\n") }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxIqStream
  
  // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>
  private var daxIqStreamStatus = "0x20000000 type=dax_iq daxiq_channel=3 pan=0x40000000 ip=10.0.1.107 daxiq_rate=48000"
  func testDaxIqParse() {
    let type = "DaxIqStream"
    let id = daxIqStreamStatus.components(separatedBy: " ").first!.streamId!
    var existingObjects = false
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      daxIqStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.daxIqStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxIqStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxIqStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Previous \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        DaxIqStream.parseStatus(radio!, daxIqStreamStatus.keyValuesArray(), true)
        
        if radio!.daxIqStreams.count == 1 {
          if let object = radio!.daxIqStreams[id] {
            
            if showInfoMessages { Swift.print("***** \(type) object added\n") }
            
            XCTAssertEqual(object.id, id, "id", file: #function)
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, "clientHandle", file: #function)
            XCTAssertEqual(object.channel, 3, "channel", file: #function)
            XCTAssertEqual(object.ip, "10.0.1.107", "ip", file: #function)
            XCTAssertEqual(object.isActive, false, "isActive", file: #function)
            XCTAssertEqual(object.pan, "0x40000000".streamId, "pan", file: #function)
            XCTAssertEqual(object.rate, 48_000, "rate", file: #function)
            
            if showInfoMessages { Swift.print("***** \(type) object properties verified") }
            
            object.ip = "11.1.1.108"
            object.rate = 96_000
            
            if showInfoMessages { Swift.print("\n***** \(type) object properties modified") }
            
            XCTAssertEqual(object.id, id, "id", file: #function)
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, "clientHandle", file: #function)
            XCTAssertEqual(object.ip, "11.1.1.108", "ip", file: #function)
            XCTAssertEqual(object.rate, 96_000, "rate", file: #function)
            
            if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
            
          } else {
            XCTFail("----->>>>> \(type) object NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> \(type) object NOT created <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testDaxIqStream() {
    let type = "DaxIqStream"
    var existingObjects = false
    
    Swift.print("\n***** \(#function)" + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      if radio!.daxIqStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxIqStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxIqStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // get new
        radio!.requestDaxIqStream("3")
        sleep(2)
        // verify added
        if radio!.daxIqStreams.count == 1 {
          
          if let object = radio!.daxIqStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
            
            // save params
            let firstId = object.id
            let clientHandle  = object.clientHandle
            let channel       = object.channel
            let ip            = object.ip
            let isActive      = object.isActive
            let pan           = object.pan
            let rate          = object.rate
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.daxIqStreams[firstId]!.remove()
            sleep(2)
            if radio!.daxIqStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
              
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }

              // get new
              radio!.requestDaxIqStream("3")
              sleep(2)
              
              // verify added
              if radio!.daxIqStreams.count == 1 {
                if let object = radio!.daxIqStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  // check params
                  let secondId = object.id
                  XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function)
                  XCTAssertEqual(object.channel, channel, "channel", file: #function)
                  XCTAssertEqual(object.ip, ip, "ip", file: #function)
                  XCTAssertEqual(object.isActive, isActive, "isActive", file: #function)
                  XCTAssertEqual(object.pan, pan, "pan", file: #function)
                  XCTAssertEqual(object.rate, rate, "rate", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.daxIqStreams[secondId]!.remove()
                  sleep(2)
                  if radio!.daxIqStreams.count == 0 {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object removal confirmed\n") }
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object NOT found <<<<<-----", file: #function)
                }
              } else {
                XCTFail("----->>>>> 2nd \(type) object NOT added <<<<<-----", file: #function)
              }
            } else {
              XCTFail("----->>>>> 1st \(type) object removal FAILED <<<<<-----", file: #function)
            }
          } else {
            XCTFail("----->>>>> 1st \(type) object  NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> 1st \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream
  
  // Format:  <streamId, > <"type", "dax_mic"> <"client_handle", handle> <"ip", ipAddress>
  private var daxMicAudioStreamStatus = "0x04000008 type=dax_mic ip=192.168.1.162"
  func testDaxMicAudioStreamParse() {
    let type = "DaxMicAudioStream"
    let id = daxMicAudioStreamStatus.components(separatedBy: " ").first!.streamId!
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      daxMicAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.daxMicAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxMicAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
                
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        DaxMicAudioStream.parseStatus(radio!, Array(daxMicAudioStreamStatus.keyValuesArray()), true)
        sleep(2)
        
        if let object = radio!.daxMicAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.ip, "192.168.1.162", "ip", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object properties verified\n") }
          
          object.ip = "12.2.3.218"
          
          if showInfoMessages { Swift.print("***** \(type) object properties modified") }
          
          XCTAssertEqual(object.id, id, "id", file: #function)
          XCTAssertEqual(object.ip, "12.2.3.218", "ip", file: #function)
          
          if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testDaxMicAudioStream() {
    let type = "DaxMicAudioStream"
    var clientHandle : Handle = 0
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      if radio!.daxMicAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxMicAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Previous \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // ask for new
        radio!.requestDaxMicAudioStream()
        sleep(2)
        // verify added
        if radio!.daxMicAudioStreams.count == 1 {
          
          if let object = radio!.daxMicAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) Object added\n") }
            
            // save params
            let firstId = object.id
            clientHandle = object.clientHandle
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.daxMicAudioStreams[firstId]!.remove()
            sleep(2)
            if radio!.daxMicAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
                            
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }
              
              // ask new
              radio!.requestDaxMicAudioStream()
              sleep(2)
              // verify added
              if radio!.daxMicAudioStreams.count == 1 {
                if let object = radio!.daxMicAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  let id = object.id
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.daxMicAudioStreams[id]!.remove()
                  sleep(2)
                  if radio!.daxMicAudioStreams[id] == nil {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object removal confirmed\n") }
                    
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object NOT found <<<<<-----", file: #function)
                }
              } else {
                XCTFail("----->>>>> 2nd \(type) object NOT added <<<<<-----", file: #function)
              }
            } else {
              XCTFail("----->>>>> 1st \(type) object removal FAILED <<<<<-----", file: #function)
            }
          } else {
            XCTFail("----->>>>> 1st \(type) object NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> 1st \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxRxAudioStream
  
  // Format:  <streamId, > <"type", "dax_rx"> <"dax_channel", channel> <"slice", sliceLetter>  <"client_handle", handle> <"ip", ipAddress
  private var daxRxAudioStreamStatus = "0x04000008 type=dax_rx dax_channel=2 slice=A ip=192.168.1.162"
  func testDaxRxAudioParse() {
    let type = "DaxRxAudioStream"
    let id = daxRxAudioStreamStatus.components(separatedBy: " ").first!.streamId!
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      daxRxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.daxRxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxRxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxRxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        DaxRxAudioStream.parseStatus(radio!, Array(daxRxAudioStreamStatus.keyValuesArray()), true)
        sleep(2)
        
        if let object = radio!.daxRxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.daxChannel, 2, "daxChannel", file: #function)
          XCTAssertEqual(object.ip, "192.168.1.162", "ip", file: #function)
          XCTAssertEqual(object.slice, nil, "slice", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object properties verified") }
          
          object.daxChannel = 4
          object.ip = "12.2.3.218"
          object.slice = radio!.slices["0".objectId!]
          
          if showInfoMessages { Swift.print("***** \(type) object properties modified") }
          
          XCTAssertEqual(object.id, id, "id", file: #function)
          XCTAssertEqual(object.daxChannel, 4, "daxChannel", file: #function)
          XCTAssertEqual(object.ip, "12.2.3.218", "ip", file: #function)
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!], "slice", file: #function)
          
          if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT created <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> \(type) object removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testDaxRxAudio() {
    let type = "DaxRxAudioStream"
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      if radio!.daxRxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxRxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxRxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // ask for new
        radio!.requestDaxRxAudioStream("2")
        sleep(2)
        // verify added
        if radio!.daxRxAudioStreams.count == 1 {
          
          if let object = radio!.daxRxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
            
            let firstId = object.id
            
            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let slice = object.slice
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.daxRxAudioStreams[firstId]!.remove()
            sleep(2)
            if radio!.daxRxAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
              
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }
              
              // ask new
              radio!.requestDaxRxAudioStream( "2")
              sleep(2)
              
              // verify added
              if radio!.daxRxAudioStreams.count == 1 {
                if let object = radio!.daxRxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  let secondId = object.id
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function)
                  XCTAssertEqual(object.daxChannel, daxChannel, "daxChannel", file: #function)
                  XCTAssertEqual(object.slice, slice, "slice", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.daxRxAudioStreams[secondId]!.remove()
                  sleep(2)
                  if radio!.daxRxAudioStreams.count == 0 {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object removal confirmed\n") }
                    
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED *****", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object NOT found <<<<<-----", file: #function)
                }
              } else {
                XCTFail("----->>>>> 2nd \(type) object NOT added <<<<<-----", file: #function)
              }
            } else {
              XCTFail("----->>>>> 1st \(type) object removal FAILED <<<<<-----", file: #function)
            }
          } else {
            XCTFail("----->>>>> 1st \(type) object NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> 1st \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxTxAudioStream
  
  // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"tx", isTransmitChannel>
  private var daxTxAudioStreamStatus = "0x0400000A type=dax_tx tx=1"
  func testDaxTxAudioParse() {
    let type = "DaxTxAudioStream"
    let id = daxTxAudioStreamStatus.components(separatedBy: " ").first!.streamId!
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      daxTxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.daxTxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxTxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxTxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) objects removal confirmed") }
                
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        DaxTxAudioStream.parseStatus(radio!, Array(daxTxAudioStreamStatus.keyValuesArray()), true)
        sleep(2)
        
        if let object = radio!.daxTxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.isTransmitChannel, true, "isTransmitChannel", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object properties verified\n") }
          
          object.isTransmitChannel = false
          
          if showInfoMessages { Swift.print("***** \(type) object properties modified") }
          
          XCTAssertEqual(object.isTransmitChannel, false, "isTransmitChannel", file: #function)
          
          if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testDaxTxAudio() {
    let type = "DaxTxAudioStream"
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      if radio!.daxTxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.daxTxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.daxTxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // get new
        radio!.requestDaxTxAudioStream()
        sleep(2)
        
        // verify added
        if radio!.daxTxAudioStreams.count == 1 {
          
          if let object = radio!.daxTxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
            
            // save params
            let firstId = object.id
            let clientHandle = object.clientHandle
            let isTransmitChannel = object.isTransmitChannel
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.daxTxAudioStreams[firstId]!.remove()
            sleep(2)
            if radio!.daxTxAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
              
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }
              
              // get new
              radio!.requestDaxTxAudioStream()
              sleep(2)

              // verify added
              if radio!.daxTxAudioStreams.count == 1 {
                if let object = radio!.daxTxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  let secondId = object.id
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function)
                  XCTAssertEqual(object.isTransmitChannel, isTransmitChannel, "isTransmitChannel", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                                      
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.daxTxAudioStreams[secondId]!.remove()
                  sleep(2)
                  if radio!.daxTxAudioStreams.count == 0 {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object removal confirmed\n") }
                  
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object NOT found <<<<<-----", file: #function)
                }
              } else {
                XCTFail("----->>>>> 2nd \(type) object NOT added <<<<<-----", file: #function)
              }
            } else {
              XCTFail("----->>>>> 1st \(type) object removal FAILED <<<<<-----", file: #function)
            }
          } else {
            XCTFail("----->>>>> 1st \(type) object NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> 1st \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteRxAudioStream
  
  private var remoteRxAudioStreamStatus = "0x04000008 type=remote_audio_rx compression=NONE ip=192.168.1.162"
  func testRemoteRxAudioStreamParse() {
    let type = "RemoteRxAudioStream"
    let id = remoteRxAudioStreamStatus.components(separatedBy: " ").first!.streamId!
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      remoteRxAudioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.remoteRxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.remoteRxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.remoteRxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        RemoteRxAudioStream.parseStatus(radio!, Array(remoteRxAudioStreamStatus.keyValuesArray()), true)
        sleep(2)
        
        if let object = radio!.remoteRxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, "clientHandle", file: #function)
          XCTAssertEqual(object.compression, "none", "compression", file: #function)
          XCTAssertEqual(object.ip, "192.168.1.162", "ip", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object properties verified") }
          
          object.compression = "NONE"
          object.ip = "193.169.2.163"
          
          if showInfoMessages { Swift.print("\n***** \(type) object properties modified") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, "clientHandle", file: #function)
          XCTAssertEqual(object.compression, "NONE", "compression", file: #function)
          XCTAssertEqual(object.ip, "193.169.2.163", "ip", file: #function)
          
          if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testRemoteRxAudioStream() {
    let type = "RemoteRxAudioStream"
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      if radio!.remoteRxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.remoteRxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }

      if radio!.remoteRxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // ask for new
        radio!.requestRemoteRxAudioStream(compression: RemoteRxAudioStream.Compression.none.rawValue)
        sleep(2)
        if radio!.remoteRxAudioStreams.count == 1 {
          
          if let object = radio!.remoteRxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
            
            let firstId = object.id
            
            let clientHandle = object.clientHandle
            let compression = object.compression
            let ip = object.ip
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            radio!.remoteRxAudioStreams[firstId]!.remove()
            sleep(2)
            if radio!.remoteRxAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
              
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }
              
              radio!.requestRemoteRxAudioStream(compression: RemoteRxAudioStream.Compression.none.rawValue)
              sleep(2)
              
              if radio!.remoteRxAudioStreams.count == 1 {
                if let object = radio!.remoteRxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  let secondId = object.id
                  
                  XCTAssertEqual(object.clientHandle, clientHandle, file: #function)
                  XCTAssertEqual(object.compression, compression, file: #function)
                  XCTAssertEqual(object.ip, ip, file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  radio!.remoteRxAudioStreams[secondId]!.remove()
                  sleep(2)
                  if radio!.remoteRxAudioStreams.count == 0 {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object removal confirmed\n") }
                    
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object NOT found <<<<<-----", file: #function)
                }
              } else {
                XCTFail("----->>>>> 2nd \(type) object NOT added <<<<<-----", file: #function)
              }
            } else {
              XCTFail("----->>>>> 1st \(type) object removal FAILED <<<<<-----", file: #function)
            }
          } else {
            XCTFail("----->>>>> 1st \(type) object NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> 1st \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Previous \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteTxAudioStream
  
  private var remoteTxAudioStreamStatus_1 = "0x84000000 type=remote_audio_tx compression=none ip=192.168.1.162"
  private var remoteTxAudioStreamStatus_2 = "0x84000000 type=remote_audio_tx compression=opus ip=192.168.1.162"
  func testRemoteTxParseAudioStream_1() {
    let type = "RemoteTxAudioStream"
    let id = remoteTxAudioStreamStatus_1.components(separatedBy: " ").first!.streamId!
    var existingObjects = false
    
    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      remoteTxAudioStreamStatus_1 += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.remoteTxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.remoteTxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.remoteTxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
                
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        RemoteTxAudioStream.parseStatus(radio!, Array(remoteTxAudioStreamStatus_1.keyValuesArray()), true)
        sleep(2)
        
        if let object = radio!.remoteTxAudioStreams[id] {
                  
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, file: #function)
          XCTAssertEqual(object.compression, "none", file: #function)
          XCTAssertEqual(object.ip, "192.168.1.162", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object properties verified\n") }
          
          object.compression = "opus"
          object.ip = "193.169.2.163"
          
          if showInfoMessages { Swift.print("***** \(type) object properties modified") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, file: #function)
          XCTAssertEqual(object.compression, "opus", file: #function)
          XCTAssertEqual(object.ip, "193.169.2.163", file: #function)
          
          if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testRemoteTxParseAudioStream_2() {
    let type = "RemoteTxAudioStream"
    let id = remoteTxAudioStreamStatus_2.components(separatedBy: " ").first!.streamId!
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      remoteTxAudioStreamStatus_2 += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      
      if radio!.remoteTxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.remoteTxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.remoteTxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects{ Swift.print("***** Existing \(type) object(s) removal confirmed") }
                
        if showInfoMessages { Swift.print("\n***** \(type) object requested") }
        
        RemoteTxAudioStream.parseStatus(radio!, Array(remoteTxAudioStreamStatus_2.keyValuesArray()), true)
        sleep(2)
        
        if let object = radio!.remoteTxAudioStreams[id] {
          
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.compression, "opus", "compression", file: #function)
          XCTAssertEqual(object.ip, "192.168.1.162", "ip", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object properties verified\n") }
          
          object.compression = "none"
          object.ip = "193.169.2.163"
          
          if showInfoMessages { Swift.print("***** \(type) object properties modified") }
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!, "clientHandle", file: #function)
          XCTAssertEqual(object.compression, "none", "compression", file: #function)
          XCTAssertEqual(object.ip, "193.169.2.163", "ip", file: #function)
          
          if showInfoMessages { Swift.print("***** Modified \(type) object properties verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> Existing \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testRemoteTxAudioStream() {
    let type = "RemoteTxAudioStream"
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isNewApi {
      
      if radio!.remoteTxAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.remoteTxAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.remoteTxAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        radio!.requestRemoteTxAudioStream(compression: "none")
        sleep(2)
        if radio!.remoteTxAudioStreams.count == 1 {
          
          if let object = radio!.remoteTxAudioStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
            
            let firstId = object.id
            
            XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle, "clientHandle", file: #function)
            XCTAssertEqual(object.compression, "none", "compression", file: #function)
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            radio!.remoteTxAudioStreams[firstId]!.remove()
            sleep(2)
            if radio!.remoteTxAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
              
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }
              
              radio!.requestRemoteTxAudioStream(compression: "opus")
              sleep(2)
              if radio!.remoteTxAudioStreams.count == 1 {
                if let object = radio!.remoteTxAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  let secondId = object.id
                  
                  XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle, "clientHandle", file: #function)
                  XCTAssertEqual(object.compression, "opus", "compression", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  radio!.remoteTxAudioStreams[secondId]!.remove()
                  sleep(2)
                  if radio!.remoteTxAudioStreams.count == 0 {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object(s) removal confirmed\n") }
                    
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object NOT found <<<<<-----", file: #function)
                }
              } else {
                XCTFail("----->>>>> 2nd \(type) object NOT added <<<<<-----", file: #function)
              }
            } else {
              XCTFail("----->>>>> 1st \(type) object removal FAILED <<<<<-----", file: #function)
            }
          } else {
            XCTFail("----->>>>> 1st \(type) object NOT found <<<<<-----", file: #function)
          }
        } else {
          XCTFail("----->>>>> 1st \(type) object NOT added <<<<<-----*", file: #function)
        }
      } else {
        XCTFail("----->>>>> Previous \(type) object(s) removal FAILED <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
}
