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
      
      Swift.print("\n***** Radio found (v\(discovery.discoveredRadios[0].firmwareVersion))\n")

      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "AudioTests", logState: logState) {
        sleep(1)
        
        Swift.print("***** Connected")
        
        return Api.sharedInstance.radio
      } else {
        XCTFail("\n***** Failed to connect to Radio *****\n")
        return nil
      }
    } else {
      XCTFail("\n***** No Radio(s) found *****\n")
      return nil
    }
  }
  
  func disconnect() {
    Api.sharedInstance.disconnect()
    
    Swift.print("\n***** Disconnected\n")
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
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "AudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      AudioStream.parseStatus(radio!, Array(audioStreamStatus.keyValuesArray()), true)
      sleep(1)
      
      if let object = radio!.audioStreams["0x40000009".streamId!] {
        
        Swift.print("***** AUDIOSTREAM object created")
        
        XCTAssertEqual(object.id, "0x40000009".streamId!)

        XCTAssertEqual(object.daxChannel, 3)
        XCTAssertEqual(object.ip, "10.0.1.107")
        XCTAssertEqual(object.port, 4124)
        XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
        
        Swift.print("***** AUDIOSTREAM object parameters verified")
        
      } else {
        XCTFail("***** AUDIOSTREAM object NOT created *****")
      }
      
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testAudioStream() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "AudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.audioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.audioStreams.count == 0 {
        
        Swift.print("***** Existing AUDIOSTREAM object(s) removed")
        
        // ask for new
        radio!.requestAudioStream( "2")
        sleep(1)
        
        Swift.print("***** 1st AUDIOSTREAM object requested")
        
        // verify added
        if radio!.audioStreams.count == 1 {
          
          Swift.print("***** 1st AUDIOSTREAM object created")
          
          if let object = radio!.audioStreams.first?.value {
            
            let id = object.id
            let clientHandle = object.clientHandle
            let daxChannel = object.daxChannel
            let ip = object.ip
            let port = object.port
            let slice = object.slice
            
            Swift.print("***** 1st AUDIOSTREAM object parameters saved")
            
            // remove it
            radio!.audioStreams[id]!.remove()
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              Swift.print("***** 1st AUDIOSTREAM object removed")
              
              // ask for new
              radio!.requestAudioStream( "2")
              sleep(1)
              
              Swift.print("***** 2nd AUDIOSTREAM object requested")
              
              // verify added
              if radio!.audioStreams.count == 1 {
                if let object = radio!.audioStreams.first?.value {
                  
                  Swift.print("***** 2nd AUDIOSTREAM object created")
                  
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, daxChannel)
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.port, port)
                  XCTAssertEqual(object.slice, slice)
                  
                  Swift.print("***** 2nd AUDIOSTREAM object parameters verified")
                  
                  object.daxChannel = 4
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  object.slice = radio!.slices["0".objectId!]
                  
                  Swift.print("***** 2nd AUDIOSTREAM object parameters modified")
                  
                  XCTAssertEqual(object.clientHandle, clientHandle)
                  XCTAssertEqual(object.daxChannel, 4)
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
                  
                  Swift.print("***** 2nd AUDIOSTREAM object modified parameters verified")
                  
                } else {
                  XCTFail("***** 2nd AUDIOSTREAM object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd AUDIOSTREAM object NOT created")
              }
            } else {
              XCTFail("***** 1st AUDIOSTREAM object NOT removed")
            }
          } else {
            XCTFail("***** 1st AUDIOSTREAM object NOT found")
          }
        } else {
          XCTFail("***** 1st AUDIOSTREAM object NOT created")
        }
      } else {
        XCTFail("***** Existing AUDIOSTREAM object(s) NOT removed")
      }
      // remove all
      radio!.audioStreams.forEach( {$0.value.remove() } )

    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - IqStream

  private var iqStreamStatus1 = "3 pan=0x0 rate=48000 capacity=16 available=16"
  func testIqStreamParse1() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "IqStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {

      IqStream.parseStatus(radio!, Array(iqStreamStatus1.keyValuesArray()), true)
      sleep(1)

      if let object = radio!.iqStreams["3".streamId!] {

        Swift.print("***** IQSTREAM object created")

        XCTAssertEqual(object.id, "3".streamId!)

        XCTAssertEqual(object.available, 16)
        XCTAssertEqual(object.capacity, 16)
        XCTAssertEqual(object.pan, "0x0".streamId!)
        XCTAssertEqual(object.rate, 48_000)

        Swift.print("***** IQSTREAM object parameters verified")

      } else {
        XCTFail("***** IQSTREAM object NOT created *****")
      }

    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }

  private var iqStreamStatus2 = "3 daxiq=4 pan=0x0 rate=48000 ip=10.0.1.100 port=4992 streaming=1 capacity=16 available=16"
  func testIqStreamParse2() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "IqStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {

      IqStream.parseStatus(radio!, Array(iqStreamStatus2.keyValuesArray()), true)
      sleep(1)

      if let object = radio!.iqStreams["3".streamId!] {

        Swift.print("***** IQSTREAM object created")

        XCTAssertEqual(object.id, "3".streamId!)

        XCTAssertEqual(object.available, 16)
        XCTAssertEqual(object.capacity, 16)
        XCTAssertEqual(object.pan, "0x0".streamId!)
        XCTAssertEqual(object.rate, 48_000)
        XCTAssertEqual(object.ip, "10.0.1.100")
        XCTAssertEqual(object.port, 4992)
        XCTAssertEqual(object.streaming, true)

        Swift.print("***** IQSTREAM object parameters verified")

      } else {
        XCTFail("***** IQSTREAM object NOT created *****")
      }

    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }

  private var iqStreamStatus3 = "3 daxiq=4 pan=0x0 daxiq_rate=48000 capacity=16 available=16"
  func testIqStreamParse3() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "IqStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {

      IqStream.parseStatus(radio!, Array(iqStreamStatus3.keyValuesArray()), true)
      sleep(1)

      if let object = radio!.iqStreams["3".streamId!] {

        Swift.print("***** IQSTREAM object created")

        XCTAssertEqual(object.id, "3".streamId!)

        XCTAssertEqual(object.available, 16)
        XCTAssertEqual(object.capacity, 16)
        XCTAssertEqual(object.pan, "0x0".streamId!)
        XCTAssertEqual(object.rate, 48_000)

        Swift.print("***** IQSTREAM object parameters verified")

      } else {
        XCTFail("***** IQSTREAM object NOT created *****")
      }

    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }

  func testIqStream() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "IqStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.iqStreams.forEach { $0.value.remove() }
      sleep(1)
      if radio!.iqStreams.count == 0 {
        
        Swift.print("***** Existing IQSTREAM object(s) removed")
        
        // get new
        radio!.requestIqStream("3")
        sleep(1)
        
        Swift.print("***** 1st IQSTREAM object requested")
        
        // verify added
        if radio!.iqStreams.count == 1 {
          
          if let object = radio!.iqStreams.first?.value {
            
            Swift.print("***** 1st IQSTREAM object created")
            
            let id            = object.id
            
            let available     = object.available
            let capacity      = object.capacity
            let pan           = object.pan
            let rate          = object.rate
            
            Swift.print("***** 1st IQSTREAM object parameters saved")
            
            // remove it
            radio!.iqStreams[id]!.remove()
            sleep(1)
            
            if radio!.iqStreams.count == 0 {
              
              Swift.print("***** 1st IQSTREAM object removed")
              
              // get new
              radio!.requestIqStream("3")
              sleep(1)
              
              Swift.print("***** 2nd IQSTREAM object requested")
              
              // verify added
              if radio!.iqStreams.count == 1 {
                if let object = radio!.iqStreams.first?.value {
                  
                  Swift.print("***** 2nd IQSTREAM object created")
                  
                  XCTAssertEqual(object.available, available)
                  XCTAssertEqual(object.capacity, capacity)
                  XCTAssertEqual(object.pan, pan)
                  XCTAssertEqual(object.rate, rate)
                  
                  Swift.print("***** 2nd IQSTREAM object parameters verified")
                  
                  object.rate = rate * 2
                  
                  Swift.print("***** 2nd IQSTREAM object parameters modified")
                  
                  XCTAssertEqual(object.available, available)
                  XCTAssertEqual(object.capacity, capacity)
                  XCTAssertEqual(object.pan, pan)
                  XCTAssertEqual(object.rate, rate * 2)
                  
                  Swift.print("***** 2nd IQSTREAM object modified parameters verified")
                  
                } else {
                  XCTFail("***** 2nd IQSTREAM object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd IQSTREAM object NOT added *****")
              }
            } else {
              XCTFail("***** 1st IQSTREAM object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st IQSTREAM object NOT found *****")
          }
        } else {
          XCTFail("***** 1st IQSTREAM object NOT created *****")
        }
      } else {
        XCTFail("***** Existing IQSTREAM object(s) NOT removed *****")
      }
      // remove all
      radio!.iqStreams.forEach { $0.value.remove() }
      
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - MicAudioStream
  
  private var micAudioStreamStatus = "0x04000009 in_use=1 ip=192.168.1.162 port=4991"
  func testMicAudioStreamParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "MicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      MicAudioStream.parseStatus(radio!, micAudioStreamStatus.keyValuesArray(), true)
      sleep(1)
      
      if let object = radio!.micAudioStreams["0x04000009".streamId!] {
        
        Swift.print("***** MICAUDIOSTREAM object created")
        
        XCTAssertEqual(object.id, "0x04000009".streamId!)

        XCTAssertEqual(object.ip, "192.168.1.162")
        XCTAssertEqual(object.port, 4991)
        
        Swift.print("***** MICAUDIOSTREAM object Properties verified")
        
      } else {
        XCTAssertTrue(false, "***** MICAUDIOSTREAM object NOT created")
      }
      
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testMicAudioStream() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "MicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.micAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.micAudioStreams.count == 0 {
        
        Swift.print("***** Existing MICAUDIOSTREAM object(s) removed")
        
        // ask new
        radio!.requestMicAudioStream()
        sleep(1)
        
        Swift.print("***** 1st MICAUDIOSTREAM object requested")
        
        // verify added
        if radio!.micAudioStreams.count == 1 {
          
          Swift.print("***** 1st MICAUDIOSTREAM object created")
          
          if let object = radio!.micAudioStreams.first?.value {
            
            let id = object.id
            
            let ip = object.ip
            let port = object.port
            
            Swift.print("***** 1st MICAUDIOSTREAM object parameters saved")
            
            // remove it
            radio!.micAudioStreams[id]!.remove()
            sleep(1)
            
            if radio!.micAudioStreams.count == 0 {
              
              Swift.print("***** 1st MICAUDIOSTREAM object removed")
              
              // ask new
              radio!.requestMicAudioStream()
              sleep(1)
              
              Swift.print("***** 2nd MICAUDIOSTREAM object requested")
              
              // verify added
              if radio!.micAudioStreams.count == 1 {
                if let object = radio!.micAudioStreams.first?.value {
                  
                  Swift.print("***** 2nd MICAUDIOSTREAM object created")
                  
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.port, port)
                  
                  Swift.print("***** 2nd MICAUDIOSTREAM object parameters verified")
                  
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  
                  Swift.print("***** 2nd MICAUDIOSTREAM object parameters modified")
                  
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  
                  Swift.print("***** 2nd MICAUDIOSTREAM object modified parameters verified")
                  
                } else {
                  XCTFail("***** 2nd MICAUDIOSTREAM object NOT removed *****")
                }
              } else {
                XCTFail("***** 2nd MICAUDIOSTREAM object NOT added *****")
              }
            } else {
              XCTFail("***** 1st MICAUDIOSTREAM object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st MICAUDIOSTREAM object NOT found *****")
          }
        } else {
          XCTFail("***** 1st MICAUDIOSTREAM object NOT added *****")
        }
      } else {
        XCTFail("***** Existing MICAUDIOSTREAM object(s) NOT removed *****")
      }
      // remove all
      radio!.iqStreams.forEach { $0.value.remove() }
      
    } else {
      Swift.print("***** \(#function) skipped, requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - TxAudioStream
  
  private var txAudioStreamStatus = "0x84000000 in_use=1 dax_tx=0 ip=192.168.1.162 port=4991"
  
  func testTxAudioStreamParse() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "TxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
        TxAudioStream.parseStatus(radio!, txAudioStreamStatus.keyValuesArray(), true)
        sleep(1)
        
        if let object = radio!.txAudioStreams["0x84000000".streamId!] {
          
          Swift.print("***** TXAUDIOSTREAM object created")
          
          XCTAssertEqual(object.ip, "192.168.1.162")
          XCTAssertEqual(object.port, 4991)
          XCTAssertEqual(object.transmit, false)
          
          Swift.print("***** TXAUDIOSTREAM object Properties verified")
                    
        } else {
          XCTFail("***** TXAUDIOSTREAM object NOT created *****")
        }
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testTxAudioStream() {
    
    Swift.print("\n***** \(#function), " + requiredVersion)
    
    let radio = discoverRadio(logState: .limited(to: "TxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.txAudioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.txAudioStreams.count == 0 {
        
        Swift.print("***** Existing TXAUDIOSTREAM object(s) removed")

        // ask for a new AudioStream
        radio!.requestTxAudioStream()
        sleep(1)
        
        Swift.print("***** 1st TXAUDIOSTREAM object requested")
        
        // verify AudioStream added
        if radio!.txAudioStreams.count == 1 {
          
          Swift.print("***** 1st TXAUDIOSTREAM object created")
          
          if let object = radio!.txAudioStreams.first?.value {
            
            let id = object.id
            
            let transmit = object.transmit
            let ip = object.ip
            let port = object.port
            
            Swift.print("***** 1st TXAUDIOSTREAM object parameters saved")
            
            // remove it
            radio!.txAudioStreams[id]!.remove()
            sleep(1)
            if radio!.txAudioStreams.count == 0 {
              
              Swift.print("***** 1st TXAUDIOSTREAM object removed")
              
              // ask new
              radio!.requestTxAudioStream()
              sleep(1)
              
              Swift.print("***** 2nd TXAUDIOSTREAM object requested")
              
              // verify added
              if radio!.txAudioStreams.count == 1 {
                
                if let object = radio!.txAudioStreams.first?.value {
                  
                  Swift.print("***** 2nd TXAUDIOSTREAM object created")
                  
                  XCTAssertEqual(object.transmit, transmit)
                  XCTAssertEqual(object.ip, ip)
                  XCTAssertEqual(object.port, port)
                  
                  let id = object.id
                  
                  Swift.print("***** 2nd TXAUDIOSTREAM object parameters verified")
                  
                  // change properties
                  object.transmit = false
                  object.ip = "12.2.3.218"
                  object.port = 4214
                  
                  Swift.print("***** 2nd TXAUDIOSTREAM object parameters modified")
                  
                  // re-verify properties
                  XCTAssertEqual(object.transmit, false)
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  
                  Swift.print("***** 2nd TXAUDIOSTREAM object modified parameters verified")
                  
                } else {
                  XCTFail("***** 2nd TXAUDIOSTREAM object NOT found *****")
                }
              } else {
                XCTFail("***** 2nd TXAUDIOSTREAM object NOT added *****")
              }
            } else {
              XCTFail("***** 1st TXAUDIOSTREAM object NOT removed *****")
            }
          } else {
            XCTFail("***** 1st TXAUDIOSTREAM object NOT found *****")
          }
        } else {
          XCTFail("***** 1st TXAUDIOSTREAM object NOT created *****")
        }
      } else {
        XCTFail("***** Existing TXAUDIOSTREAM object(s) NOT removed *****")
      }
      // remove all
      radio!.txAudioStreams.forEach { $0.value.remove() }

    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Opus
  
  func testOpusParse() {
    
    let radio = discoverRadio(logState: .limited(to: "Opus.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
  
  func testOpus() {
    
    let radio = discoverRadio(logState: .limited(to: "Opus.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****")
      
    } else {
      Swift.print("SKIPPED: \(#function) requires \(requiredVersion)")
    }
    disconnect()
  }
}
