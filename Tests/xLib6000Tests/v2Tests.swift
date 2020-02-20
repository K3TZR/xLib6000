//
//  v2Tests.swift
//  xLib6000Tests
//
//  Created by Douglas Adams on 2/15/20.
//

import XCTest
@testable import xLib6000

class v2Tests: XCTestCase {
  let requiredVersion = "v1 or v2"

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
        XCTFail("***** Failed to connect to Radio *****")
        return nil
      }
    } else {
      XCTFail("***** No Radio(s) found *****")
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
  
  ///   Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
  private var audioStreamStatus = "0x40000009 dax=3 slice=0 ip=10.0.1.107 port=4124"
  func testAudioParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "AudioStream.swift"))
    guard radio != nil else { return }
    
    audioStreamStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.audioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.audioStreams.count == 0 {
        
        Swift.print("***** Existing object(s) removed")
        
        AudioStream.parseStatus(radio!, Array(audioStreamStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.audioStreams["0x40000009".streamId!] {
          
          Swift.print("***** Object created")
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.daxChannel, 3)
          XCTAssertEqual(object.ip, "10.0.1.107")
          XCTAssertEqual(object.port, 4124)
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
          
          Swift.print("***** Properties verified")
          
          object.daxChannel = 4
          object.ip = "12.2.3.218"
          object.port = 4214
          object.slice = radio!.slices["0".objectId!]
          
          Swift.print("***** Properties modified")
          
          XCTAssertEqual(object.id, "0x40000009".streamId)
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.daxChannel, 4)
          XCTAssertEqual(object.ip, "12.2.3.218")
          XCTAssertEqual(object.port, 4214)
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTFail("***** Failed to create Object *****")
        }
      } else {
        XCTFail("***** Failed to remove Object *****")
      }
      
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testAudio() {
    let requiredVersion = "v1 or v2"
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "AudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {     // v1 and v2 ONLY
      
      // remove all
      radio!.audioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.audioStreams.count == 0 {
        
        Swift.print("***** Existing Object(s) removed")
        
        // ask for new
        radio!.requestAudioStream( "2")
        sleep(1)
        
        // verify added
        if radio!.audioStreams.count == 1 {
          
          Swift.print("***** Object added")
          
          if let object = radio!.audioStreams.first?.value {
            
            // save params
            let id = object.id
            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let ip = object.ip
            let port = object.port
            let slice = object.slice
            
            Swift.print("***** Parameters saved")
            
            // remove it
            radio!.audioStreams[id]!.remove()
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              Swift.print("***** Object removed")
              
              // ask for new
              radio!.requestAudioStream( "2")
              sleep(1)
              
              // verify added
              if radio!.audioStreams.count == 1 {
                if let object = radio!.audioStreams.first?.value {
                  
                  Swift.print("***** Object re-created")
                  
                  let id = object.id
                  
                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, daxChannel)
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.port, port)
                  XCTAssertEqual(object.slice, slice)
                  
                  Swift.print("***** Parameters verified")
                  
                  // change properties
                  object.daxChannel = 4
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  object.slice = radio!.slices["0".objectId!]
                  
                  Swift.print("***** Parameters modified")
                  
                  // re-verify properties
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, 4)
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
                  
                  Swift.print("***** Modified parameters verified")
                  
                  // remove it
                  radio!.audioStreams[id]!.remove()
                  sleep(1)
                  if radio!.audioStreams[id] == nil {
                    Swift.print("***** Object removed")
                  } else {
                    Swift.print("***** Object NOT removed")
                  }
                } else {
                  XCTFail("***** Object 0 NOT found *****")
                }
              } else {
                XCTFail("***** Object(s) NOT added")
              }
            } else {
              XCTFail("***** Object(s) NOT removed")
            }
          } else {
            XCTFail("***** Object 0 NOT found")
          }
        } else {
          XCTFail("***** Object(s) NOT added")
        }
      } else {
        XCTFail("***** Object(s) NOT removed")
      }
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - IqStream
  
  func testIqParse() {
    
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
  
  func testIq() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      for (_, stream) in radio!.iqStreams { stream.remove() }
      sleep(1)
      if radio!.iqStreams.count == 0 {
        
        // get new
        radio!.requestIqStream("3")
        sleep(1)
        
        // verify added
        if radio!.iqStreams.count == 1 {
          
          if let stream = radio!.iqStreams[0] {
            
            // save params
            let available     = stream.available
            let capacity      = stream.capacity
            //            let daxIqChannel  = stream.daxIqChannel
            //            let inUse         = stream.inUse
            let ip            = stream.ip
            let pan           = stream.pan
            let port          = stream.port
            let rate          = stream.rate
            let streaming     = stream.streaming
            
            // remove all
            for (_, stream) in radio!.iqStreams { stream.remove() }
            sleep(1)
            if radio!.iqStreams.count == 0 {
              
              // get new
              radio!.requestIqStream("3")
              sleep(1)
              
              // verify added
              if radio!.iqStreams.count == 1 {
                if let stream = radio!.iqStreams[0] {
                  
                  // check params
                  XCTAssertEqual(stream.available, available)
                  XCTAssertEqual(stream.capacity, capacity)
                  XCTAssertEqual(stream.daxIqChannel, 3)
                  XCTAssertEqual(stream.inUse, true)
                  XCTAssertEqual(stream.ip, ip)
                  XCTAssertEqual(stream.pan, pan)
                  XCTAssertEqual(stream.port, port)
                  XCTAssertEqual(stream.rate, rate)
                  XCTAssertEqual(stream.streaming, streaming)
                  
                } else {
                  XCTAssert(true, "\n***** IqStream 0 NOT found *****\n")
                }
              } else {
                XCTAssert(true, "\n***** IqStream NOT added *****\n")
              }
            } else {
              XCTAssert(true, "\n***** IqStream NOT removed *****\n")
            }
          } else {
            XCTAssert(true, "\n***** IqStream 0 NOT found *****\n")
          }
        } else {
          XCTAssert(true, "\n***** IqStream NOT added *****\n")
        }
      } else {
        XCTAssert(true, "\n***** DaxTxAudioStream(s) NOT removed *****\n")
      }
      // remove any DaxTxAudioStream
      for (_, stream) in radio!.iqStreams { stream.remove() }
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - MicAudioStream
  
  private var micAudioStatus = "0x04000009 in_use=1 ip=192.168.1.162 port=4991"
  func testMicParse() {
    let requiredVersion = "v1 or v2"
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "MicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      micAudioStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      let id = micAudioStatus.components(separatedBy: " ")[0]
      
      // remove all
      radio!.micAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.micAudioStreams.count == 0 {
        
        Swift.print("***** Existing objects removed")
        
        MicAudioStream.parseStatus(radio!, micAudioStatus.keyValuesArray(), true)
        sleep(1)
        
        if let object = radio!.micAudioStreams[id.streamId!] {
          
          Swift.print("***** Object created")
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.ip, "192.168.1.162")
          XCTAssertEqual(object.port, 4991)
          
          Swift.print("***** Properties verified")
          
          object.ip = "192.168.1.165"
          object.port = 3880
          
          Swift.print("***** Properties modified")
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.ip, "192.168.1.165")
          XCTAssertEqual(object.port, 3880)
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTAssertTrue(false, "***** Failed to create Object")
        }
      } else {
        XCTAssertTrue(false, "***** Failed to remove Object(s)")
      }
      
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testMic() {
    let requiredVersion = "v1 or v2"
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "MicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.micAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.micAudioStreams.count == 0 {
        
        Swift.print("***** Existing object(s) removed")
        
        // ask new
        radio!.requestMicAudioStream()
        sleep(1)
        
        // verify added
        if radio!.micAudioStreams.count == 1 {
          
          Swift.print("***** Object added")
          
          if let object = radio!.micAudioStreams.first?.value {
            
            let id = object.id
            let ip = object.ip
            let port = object.port
            
            Swift.print("***** Parameters saved")
            
            // remove it
            radio!.micAudioStreams[id]!.remove()
            sleep(1)
            
            if radio!.micAudioStreams.count == 0 {
              
              Swift.print("***** Object removed")
              
              // ask new
              radio!.requestMicAudioStream()
              sleep(1)
              
              // verify added
              if radio!.micAudioStreams.count == 1 {
                if let object = radio!.micAudioStreams.first?.value {
                  
                  Swift.print("***** Object re-created")
                  
                  let id = object.id
                  
                  // check params
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.port, port)
                  
                  Swift.print("***** Parameters verified")
                  
                  // change properties
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  
                  Swift.print("***** Parameters modified")
                  
                  // re-verify properties
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  
                  Swift.print("***** Modified parameters verified")
                  
                  // remove it
                  radio!.micAudioStreams[id] = nil
                  sleep(1)
                  if radio!.audioStreams[id] == nil {
                    Swift.print("***** Object removed")
                  } else {
                    XCTFail("***** Object NOT removed")
                  }
                } else {
                  XCTFail("***** 2nd Object NOT removed *****")
                }
              } else {
                XCTFail("***** 2nd Object(s) NOT added *****")
              }
            } else {
              XCTFail("***** 1st Object(s) NOT removed *****")
            }
          } else {
            XCTFail("***** 1st Object NOT found *****")
          }
        } else {
          XCTFail("***** 1st Object NOT added *****")
        }
      } else {
        XCTFail("***** Existing object(s) NOT removed *****")
      }
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - TxAudioStream
  
  private var txAudioStatus = "0x84000000 in_use=1 dax_tx=0 ip=192.168.1.162 port=4991"
  
  func testTxAudioParse() {
    let requiredVersion = "v1 or v2"
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "TxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      txAudioStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"
      let id = txAudioStatus.components(separatedBy: " ")[0]
      
      // remove all
      radio!.txAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.txAudioStreams.count == 0 {
        
        Swift.print("***** Existing objects removed")
        
        TxAudioStream.parseStatus(radio!, txAudioStatus.keyValuesArray(), true)
        sleep(1)
        
        if let object = radio!.txAudioStreams[id.streamId!] {
          
          Swift.print("***** Object created")
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.ip, "192.168.1.162")
          XCTAssertEqual(object.port, 4991)
          XCTAssertEqual(object.transmit, false)
          
          Swift.print("***** Properties verified")
          
          object.ip = "192.168.1.165"
          object.port = 3880
          object.transmit = true
          
          Swift.print("***** Properties modified")
          
          XCTAssertEqual(object.clientHandle, Api.sharedInstance.connectionHandle!)
          XCTAssertEqual(object.ip, "192.168.1.165")
          XCTAssertEqual(object.port, 3880)
          XCTAssertEqual(object.transmit, true)
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTFail("***** Failed to create new Object *****")
        }
      } else {
        XCTFail("***** Failed to remove existing Object(s) *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testTxAudio() {
    let requiredVersion = "v1 or v2"
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "TxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {     // v1 and v2 ONLY
      
      // remove all
      radio!.txAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.txAudioStreams.count == 0 {
        
        Swift.print("***** Previous Object(s) removed")
        
        // ask for a new AudioStream
        radio!.requestTxAudioStream()
        sleep(1)
        
        // verify AudioStream added
        if radio!.txAudioStreams.count == 1 {
          
          Swift.print("***** Object added")
          
          if let object = radio!.txAudioStreams.first?.value {
            
            // save params
            let id = object.id
            let transmit = object.transmit
            let ip = object.ip
            let port = object.port
            
            Swift.print("***** Parameters saved")
            
            // remove it
            radio!.txAudioStreams[id]!.remove()
            sleep(1)
            if radio!.txAudioStreams.count == 0 {
              
              Swift.print("***** Object removed")
              
              // ask new
              radio!.requestTxAudioStream()
              sleep(1)
              
              // verify added
              if radio!.txAudioStreams.count == 1 {
                
                if let object = radio!.txAudioStreams.first?.value {
                  
                  Swift.print("***** Object re-created")
                  
                  // check params
                  XCTAssertEqual(object.transmit, transmit)
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.port, port)
                  
                  let id = object.id
                  
                  Swift.print("***** Parameters verified")
                  
                  // change properties
                  object.transmit = false
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  
                  Swift.print("***** Parameters modified")
                  
                  // re-verify properties
                  XCTAssertEqual(object.transmit, false)
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  
                  Swift.print("***** Modified parameters verified")
                  
                  radio!.txAudioStreams[id]?.remove()
                  
                  if radio!.audioStreams.count == 0 {
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
        XCTFail("***** Object NOT removed *****")
      }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion): radio is v\(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  func testOpusParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  func testOpus() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
}
