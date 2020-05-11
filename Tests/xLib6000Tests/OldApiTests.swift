//
//  OldApiTests.swift
//  xLib6000Tests
//
//  Created by Douglas Adams on 2/15/20.
//

import XCTest
@testable import xLib6000

class OldApiTests: XCTestCase {
  let connectAsGui = true
  let requiredVersion = "v1 || v2 OldApi"
  let showInfoMessages = true

  // Helper functions
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("***** Radio found: \(discovery.discoveredRadios[0].nickname) (v\(discovery.discoveredRadios[0].firmwareVersion)) @ \(discovery.discoveredRadios[0].publicIp)")

      if Api.sharedInstance.connect(discovery.discoveredRadios[0], program: "v2Tests", isGui: connectAsGui, logState: logState) {
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
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - AudioStream
  
  private var audioStreamStatus = "0x40000009 dax=3 slice=0 ip=10.0.1.107 port=4124"
  func testAudioStreamParse() {
    let type = "AudioStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if showInfoMessages { Swift.print("\n***** \(type) object requested") }
      
      AudioStream.parseStatus(radio!, Array(audioStreamStatus.keyValuesArray()), true)
      sleep(2)
      
      if let object = radio!.audioStreams["0x40000009".streamId!] {
        
        if showInfoMessages { Swift.print("***** \(type) object added\n") }
        
        XCTAssertEqual(object.id, "0x40000009".streamId!)

        XCTAssertEqual(object.daxChannel, 3, "daxChannel", file: #function)
        XCTAssertEqual(object.ip, "10.0.1.107", "ip", file: #function)
        XCTAssertEqual(object.port, 4124, "port", file: #function)
        XCTAssertEqual(object.slice, radio!.slices["0".objectId!], "slice", file: #function)
        
        if showInfoMessages { Swift.print("***** \(type) object parameters verified\n") }
        
      } else {
        XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testAudioStream() {
    let type = "AudioStream"
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if radio!.audioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.audioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.audioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removal confirmed") }
                
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // ask for new
        radio!.requestAudioStream( "2")
        sleep(2)
        // verify added
        if radio!.audioStreams.count == 1 {
          
          if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
          
          if let object = radio!.audioStreams.first?.value {
            
            let firstId = object.id
//            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let ip = object.ip
            let port = object.port
            let slice = object.slice
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.audioStreams[firstId]!.remove()
            sleep(2)
            if radio!.audioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed\n") }
                            
              if showInfoMessages { Swift.print("***** 2nd \(type) object requested") }
              
              // ask for new
              radio!.requestAudioStream( "2")
              sleep(2)
              // verify added
              if radio!.audioStreams.count == 1 {
                if let object = radio!.audioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
//                  XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function)
                  XCTAssertEqual(object.daxChannel, daxChannel, "daxChannel", file: #function)
                  XCTAssertEqual(object.ip, ip, "ip", file: #function)
                  XCTAssertEqual(object.port, port, "port", file: #function)
                  XCTAssertEqual(object.slice, slice, "slice", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  let secondId = object.id
                  
                  object.daxChannel = 4
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  object.slice = radio!.slices["0".objectId!]
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object parameters modified") }
                  
//                  XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function)
                  XCTAssertEqual(object.daxChannel, 4, "daxChannel", file: #function)
                  XCTAssertEqual(object.ip, "12.2.3.218", "ip", file: #function)
                  XCTAssertEqual(object.port, 4214, "port", file: #function)
                  XCTAssertEqual(object.slice, radio!.slices["0".objectId!], "slice", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object modified parameters verified\n") }
                                    
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.audioStreams[secondId]!.remove()
                  sleep(2)
                  if radio!.audioStreams.count == 0 {
                    
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
  // MARK: - IqStream

  private var iqStreamStatus_1 = "3 pan=0x0 rate=48000 capacity=16 available=16"
  func testIqStreamParse_1() {
    let type = "IqStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if showInfoMessages { Swift.print("\n***** NOTE: 'xLib Added' messages will not be seen since 'ip' is not included in this parse") }

      if showInfoMessages { Swift.print("\n***** \(type) object requested") }

      IqStream.parseStatus(radio!, Array(iqStreamStatus_1.keyValuesArray()), true)
      sleep(2)

      if let object = radio!.iqStreams["3".streamId!] {

        if showInfoMessages { Swift.print("***** \(type) object added\n") }

        XCTAssertEqual(object.id, "3".streamId!)

        XCTAssertEqual(object.available, 16, "available", file: #function)
        XCTAssertEqual(object.capacity, 16, "capacity", file: #function)
        XCTAssertEqual(object.pan, "0x0".streamId!, "pan", file: #function)
        XCTAssertEqual(object.rate, 48_000, "rate", file: #function)

        if showInfoMessages { Swift.print("***** \(type) object parameters verified\n") }

      } else {
        XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
      }

    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }

  private var iqStreamStatus_2 = "3 daxiq=4 pan=0x0 rate=48000 ip=10.0.1.100 port=4992 streaming=1 capacity=16 available=16"
  func testIqStreamParse_2() {
    let type = "IqStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if showInfoMessages { Swift.print("\n***** \(type) object requested") }

      IqStream.parseStatus(radio!, Array(iqStreamStatus_2.keyValuesArray()), true)
      sleep(2)

      if let object = radio!.iqStreams["3".streamId!] {

        if showInfoMessages { Swift.print("***** \(type) object added\n") }

        XCTAssertEqual(object.id, "3".streamId!)

        XCTAssertEqual(object.available, 16, "available", file: #function)
        XCTAssertEqual(object.capacity, 16, "capacity", file: #function)
        XCTAssertEqual(object.pan, "0x0".streamId!, "pan", file: #function)
        XCTAssertEqual(object.rate, 48_000, "rate", file: #function)
        XCTAssertEqual(object.ip, "10.0.1.100", "ip", file: #function)
        XCTAssertEqual(object.port, 4992, "port", file: #function)
        XCTAssertEqual(object.streaming, true, "streaming", file: #function)

        if showInfoMessages { Swift.print("***** \(type) object parameters verified\n") }

      } else {
        XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
      }

    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }

  private var iqStreamStatus_3 = "3 daxiq=4 pan=0x0 daxiq_rate=48000 capacity=16 available=16"
  func testIqStreamParse3() {
    let type = "IqStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if showInfoMessages { Swift.print("\n***** NOTE: 'xLib Added' messages will not be seen since 'ip' is not included in this parse") }

      if showInfoMessages { Swift.print("\n***** \(type) object requested") }

      IqStream.parseStatus(radio!, Array(iqStreamStatus_3.keyValuesArray()), true)
      sleep(2)

      if let object = radio!.iqStreams["3".streamId!] {

        if showInfoMessages { Swift.print("***** \(type) object added\n") }

        XCTAssertEqual(object.id, "3".streamId!)

        XCTAssertEqual(object.available, 16, "available", file: #function)
        XCTAssertEqual(object.capacity, 16, "capacity", file: #function)
        XCTAssertEqual(object.pan, "0x0".streamId!, "pan", file: #function)
        XCTAssertEqual(object.rate, 48_000, "rate", file: #function)

        if showInfoMessages { Swift.print("***** \(type) object parameters verified\n") }

      } else {
        XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
      }

    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }

  func testIqStream() {
    let type = "IqStream"
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if radio!.iqStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.iqStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.iqStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removed\n") }
                
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // get new
        radio!.requestIqStream("3")
        sleep(2)
        // verify added
        if radio!.iqStreams.count == 1 {
          
          if let object = radio!.iqStreams.first?.value {
            
            if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
            
            let firstId            = object.id
            
            let available     = object.available
            let capacity      = object.capacity
            let channel       = object.daxIqChannel
            let pan           = object.pan
            let rate          = object.rate
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
                        
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.iqStreams[firstId]!.remove()
            sleep(2)
            
            if radio!.iqStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed") }
                            
              if showInfoMessages { Swift.print("\n***** 2nd \(type) object requested") }
              
              // get new
              radio!.requestIqStream("3")
              sleep(2)
              // verify added
              if radio!.iqStreams.count == 1 {
                if let object = radio!.iqStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  let secondId = object.id
                  
                  XCTAssertEqual(object.available, available, "available", file: #function)
                  XCTAssertEqual(object.capacity, capacity, "capacity", file: #function)
                  XCTAssertEqual(object.daxIqChannel, channel, "channel", file: #function)
                  XCTAssertEqual(object.pan, pan, "pan", file: #function)
                  XCTAssertEqual(object.rate, rate, "rate", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  object.rate = rate * 2
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object parameters modified") }
                  
                  XCTAssertEqual(object.available, available, "available", file: #function)
                  XCTAssertEqual(object.capacity, capacity, "capacity", file: #function)
                  XCTAssertEqual(object.daxIqChannel, channel, "channel", file: #function)
                  XCTAssertEqual(object.pan, pan, "pan", file: #function)
                  XCTAssertEqual(object.rate, rate * 2, "rate", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object modified parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.iqStreams[secondId]!.remove()
                  sleep(2)
                  
                  if radio!.iqStreams.count == 0 {
                    
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
        XCTFail("----->>>>> Existing \(type) object(s) NOT removed <<<<<-----", file: #function)
      }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - MicAudioStream
  
  private var micAudioStreamStatus = "0x04000009 in_use=1 ip=192.168.1.162 port=4991"
  func testMicAudioStreamParse() {
    let type = "MicAudioStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if showInfoMessages { Swift.print("\n***** \(type) object requested") }
      
      MicAudioStream.parseStatus(radio!, micAudioStreamStatus.keyValuesArray(), true)
      sleep(2)
      
      if let object = radio!.micAudioStreams["0x04000009".streamId!] {
        
        if showInfoMessages { Swift.print("***** \(type) object added\n") }
        
        XCTAssertEqual(object.id, "0x04000009".streamId!, file: #function)

        XCTAssertEqual(object.ip, "192.168.1.162", "ip", file: #function)
        XCTAssertEqual(object.port, 4991, "port", file: #function)
        
        if showInfoMessages { Swift.print("***** \(type) object Properties verified\n") }
        
      } else {
        XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testMicAudioStream() {
    let type = "MicAudioStream"
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if radio!.micAudioStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.micAudioStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.micAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removed\n") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // ask new
        radio!.requestMicAudioStream()
        sleep(2)

        // verify added
        if radio!.micAudioStreams.count == 1 {
          
          if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
          
          if let object = radio!.micAudioStreams.first?.value {
            
            let firstId = object.id
            
            let ip = object.ip
            let port = object.port
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
                        
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.micAudioStreams[firstId]!.remove()
            sleep(2)
            
            if radio!.micAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed\n") }
              
              if showInfoMessages { Swift.print("***** 2nd \(type)object requested") }
              
              // ask new
              radio!.requestMicAudioStream()
              sleep(2)

              // verify added
              if radio!.micAudioStreams.count == 1 {
                if let object = radio!.micAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  XCTAssertEqual(object.ip, ip, "ip", file: #function)
                  XCTAssertEqual(object.port, port, "port", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified") }
                  
                  let secondId = object.id
                  
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object parameters modified") }
                  
                  XCTAssertEqual(object.ip, "12.2.3.218", "ip", file: #function)
                  XCTAssertEqual(object.port, 4214, "port", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object modified parameters verified") }
                  
                  if showInfoMessages { Swift.print("\n***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.micAudioStreams[secondId]!.remove()
                  sleep(2)
                  
                  if radio!.iqStreams.count == 0 {
                    
                    if showInfoMessages { Swift.print("***** 2nd \(type) object removal confirmed\n") }
                    
                  } else {
                    XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
                  }
                } else {
                  XCTFail("----->>>>> 2nd \(type) object removal FAILED <<<<<-----", file: #function)
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
  // MARK: - TxAudioStream
  
  private var txAudioStreamStatus = "0x84000000 in_use=1 dax_tx=0 ip=192.168.1.162 port=4991"
  
  func testTxAudioStreamParse() {
    let type = "TxAudioStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if showInfoMessages { Swift.print("\n***** \(type) object requested") }
      
        TxAudioStream.parseStatus(radio!, txAudioStreamStatus.keyValuesArray(), true)
        sleep(2)
        
        if let object = radio!.txAudioStreams["0x84000000".streamId!] {
          
          if showInfoMessages { Swift.print("***** \(type) object added\n") }
          
          XCTAssertEqual(object.ip, "192.168.1.162", "ip", file: #function)
          XCTAssertEqual(object.port, 4991, "port", file: #function)
          XCTAssertEqual(object.transmit, false, "transmit", file: #function)
          
          if showInfoMessages { Swift.print("***** \(type) object Properties verified\n") }
                    
        } else {
          XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
        }
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testTxAudioStream() {
    let type = "TxAudioStream"
    var existingObjects = false

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      if radio!.iqStreams.count > 0 {
        existingObjects = true
        if showInfoMessages { Swift.print("\n***** Existing \(type) object(s) removed") }
        
        // remove all
        radio!.iqStreams.forEach( {$0.value.remove() } )
        sleep(2)
      }
      if radio!.txAudioStreams.count == 0 {
        
        if showInfoMessages && existingObjects { Swift.print("***** Existing \(type) object(s) removed\n") }
        
        if showInfoMessages { Swift.print("\n***** 1st \(type) object requested") }
        
        // ask for a new AudioStream
        radio!.requestTxAudioStream()
        sleep(2)

        // verify AudioStream added
        if radio!.txAudioStreams.count == 1 {
          
          if showInfoMessages { Swift.print("***** 1st \(type) object added\n") }
          
          if let object = radio!.txAudioStreams.first?.value {
            
            let firstId = object.id
            
            let transmit = object.transmit
            let ip = object.ip
            let port = object.port
            
            if showInfoMessages { Swift.print("***** 1st \(type) object parameters saved") }
            
            if showInfoMessages { Swift.print("\n***** 1st \(type) object removed") }
            
            // remove it
            radio!.txAudioStreams[firstId]!.remove()
            sleep(2)
            if radio!.txAudioStreams.count == 0 {
              
              if showInfoMessages { Swift.print("***** 1st \(type) object removal confirmed\n") }
              
              if showInfoMessages { Swift.print("***** 2nd \(type) object requested") }
              
              // ask new
              radio!.requestTxAudioStream()
              sleep(2)

              // verify added
              if radio!.txAudioStreams.count == 1 {
                
                if let object = radio!.txAudioStreams.first?.value {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object added\n") }
                  
                  XCTAssertEqual(object.transmit, transmit, "transmit", file: #function)
                  XCTAssertEqual(object.ip, ip, "ip", file: #function)
                  XCTAssertEqual(object.port, port, "port", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters verified\n") }
                  
                  // change properties
                  let secondId = object.id
                  
                  object.transmit = false
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object parameters modified") }
                  
                  // re-verify properties
                  XCTAssertEqual(object.transmit, false, "transmit", file: #function)
                  XCTAssertEqual(object.ip, "12.2.3.218", "ip", file: #function)
                  XCTAssertEqual(object.port, 4214, "port", file: #function)
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object modified parameters verified\n") }
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) object removed") }
                  
                  // remove it
                  radio!.txAudioStreams[secondId]!.remove()
                  sleep(2)
                  
                  if radio!.iqStreams.count == 0 {
                    
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
  // MARK: - Opus
 
  ///   Format:  <streamId, > <"ip", ip> <"port", port> <"opus_rx_stream_stopped", 1|0>  <"rx_on", 1|0> <"tx_on", 1|0>

  private let opusStatus = "0x50000000 ip=10.0.1.100 port=4993 opus_rx_stream_stopped=0 rx_on=0 tx_on=0"
  func testOpusAudioStreamParse() {
    let type = "OpusAudioStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {

      if showInfoMessages { Swift.print("\n***** \(type) object requested") }

      OpusAudioStream.parseStatus(radio!, Array(opusStatus.keyValuesArray()), true)
      sleep(2)

      if let object = radio!.opusAudioStreams["0x50000000".streamId!] {

        if showInfoMessages { Swift.print("***** \(type) object added\n") }

        XCTAssertEqual(object.id, "0x50000000".streamId!, file: #function)

        XCTAssertEqual(object.ip, "10.0.1.100", "ip", file: #function)
        XCTAssertEqual(object.port, 4993, "port", file: #function)
        XCTAssertEqual(object.rxStopped, false, "rxStopped", file: #function)
        XCTAssertEqual(object.rxEnabled, false, "rxEnabled", file: #function)
        XCTAssertEqual(object.txEnabled, false, "txEnabled", file: #function)

        if showInfoMessages { Swift.print("***** \(type) object parameters verified\n") }

      } else {
        XCTFail("----->>>>> \(type) object NOT added <<<<<-----", file: #function)
      }

    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
  
  func testOpusAudioStream() {
    let type = "OpusAudioStream"

    Swift.print("\n-------------------- \(#function), " + requiredVersion + " --------------------\n")

    let radio = discoverRadio(logState: .limited(to: [type + ".swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isOldApi {
      
      // verify added
      if radio!.opusAudioStreams.count == 1 {
        
        if let object = radio!.opusAudioStreams.first?.value {
          
          if showInfoMessages { Swift.print("\n***** \(type) object found") }
          
          let rxStopped = object.rxStopped
          let rxEnabled = object.rxEnabled
          let txEnabled = object.txEnabled

          if showInfoMessages { Swift.print("\n***** \(type) object parameters saved") }
          
          object.ip = "10.0.1.100"
          object.port = 5_000
          object.rxStopped = !rxStopped
          object.rxEnabled = !rxEnabled
          object.txEnabled = !txEnabled
          
          if showInfoMessages { Swift.print("\n***** \(type) object parameters modified") }
          
          XCTAssertEqual(object.ip, "10.0.1.100", "ip", file: #function)
          XCTAssertEqual(object.port, 5_000, "port", file: #function)
          XCTAssertEqual(object.rxStopped, !rxStopped, "rxStopped", file: #function)
          XCTAssertEqual(object.rxEnabled, !rxEnabled, "rxEnabled", file: #function)
          XCTAssertEqual(object.txEnabled, !txEnabled, "txEnabled", file: #function)

          if showInfoMessages { Swift.print("***** \(type) object modified parameters verified\n") }
          
        } else {
          XCTFail("----->>>>> \(type) object NOT found <<<<<-----", file: #function)
        }
      } else {
        XCTFail("----->>>>> \(type) object does NOT exist <<<<<-----", file: #function)
      }
      
    } else {
      XCTFail("----->>>>> \(#function) skipped, requires \(requiredVersion) <<<<<-----", file: #function)
    }
    disconnect()
  }
}
