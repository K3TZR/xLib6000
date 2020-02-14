//
//  AudioTests.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class AudioTests: XCTestCase {
      
  // Helper functions
  func discoverRadio(logState: Api.NSLogState = (false, "")) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("\n***** Radio found")
      
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
  // MARK: - AudioStream
   
  ///   Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
  private var audioStreamStatus = "0x40000009 dax=3 slice=0 ip=10.0.1.107 port=4124"
  func testAudioParse() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "AudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      // remove all
      radio!.audioStreams.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.audioStreams.count == 0 {
        
        Swift.print("***** Previous object(s) removed")
        
        AudioStream.parseStatus(radio!, Array(audioStreamStatus.keyValuesArray()), true)
        sleep(1)
        
        if let object = radio!.audioStreams["0x40000009".streamId!] {
          
          Swift.print("***** Object created")
          
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
          
          XCTAssertEqual(object.id, "0x23456789".streamId)
          XCTAssertEqual(object.daxChannel, 4)
          XCTAssertEqual(object.ip, "12.2.3.218")
          XCTAssertEqual(object.port, 4214)
          XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
          
          Swift.print("***** Modified properties verified")
          
        } else {
          XCTAssertTrue(false, "***** Failed to create Object *****")
        }
      } else {
        XCTAssertTrue(false, "***** Failed to remove Object(s)")
      }
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }

  func testAudio() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "AudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {     // v1 and v2 ONLY
      
      // remove any AudioStreams
      for (_, stream) in radio!.audioStreams { stream.remove() }
      sleep(1)
      if radio!.audioStreams.count == 0 {
        
        Swift.print("***** Previous Object(s) removed")
        
        // ask for a new AudioStream
        radio!.requestAudioStream( "2")
        sleep(1)
        
        // verify AudioStream added
        if radio!.audioStreams.count == 1 {
          
          Swift.print("***** Object added")
          
          if let stream = radio!.audioStreams.first?.value {
            
            // save params
            let daxChannel = stream.daxChannel
            let ip = stream.ip
            let port = stream.port
            let slice = stream.slice
            
            Swift.print("***** Parameters saved")
            
            // remove any AudioStreams
            for (_, stream) in radio!.audioStreams { stream.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              Swift.print("***** Object removed")
              
              // ask for a new AudioStream
              radio!.requestAudioStream( "2")
              sleep(1)
              
              // verify AudioStream added
              if radio!.audioStreams.count == 1 {
                if let object = radio!.audioStreams.first?.value {
                                    
                  Swift.print("***** Object re-created")
                  
                  // check params
                  XCTAssertEqual(object.id, "0x23456789".streamId)
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
                  XCTAssertEqual(object.id, "0x23456789".streamId)
                  XCTAssertEqual(object.daxChannel, 4)
                  XCTAssertEqual(object.ip, "12.2.3.218")
                  XCTAssertEqual(object.port, 4214)
                  XCTAssertEqual(object.slice, radio!.slices["0".objectId!])
                  
                  Swift.print("***** Modified parameters verified")
                  
                } else {
                  XCTAssert(true, "***** Object 0 NOT found")
                }
              } else {
                XCTAssert(true, "***** Object(s) NOT added")
              }
            } else {
              XCTAssert(true, "***** Object(s) NOT removed")
            }
          } else {
            XCTAssert(true, "***** Object 0 NOT found")
          }
        } else {
          XCTAssert(true, "***** Object(s) NOT added")
        }
      } else {
        XCTAssert(true, "***** Object(s) NOT removed")
      }
      // remove any AudioStreams
      for (_, stream) in radio!.audioStreams { stream.remove() }
    
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream
  
  // Format:  <streamId, > <"type", "dax_mic"> <"client_handle", handle> <"ip", ipAddress>
  private var daxMicAudioStatus = "0x04000008 type=dax_mic ip=192.168.1.162"

  func testDaxMicParse() {
            
        Swift.print("\n***** \(#function)")
        
        let radio = discoverRadio(logState: (true, "DaxMicAudioStream.swift"))
        guard radio != nil else { return }

        if radio!.version.isV3 {

          daxMicAudioStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())"

          // remove all
          radio!.daxMicAudioStreams.forEach( {$0.value.remove() } )
          sleep(1)
          if radio!.daxMicAudioStreams.count == 0 {
            
            Swift.print("***** Previous object(s) removed")

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
              XCTAssertTrue(false, "***** Failed to create Object")
            }
          } else {
            XCTAssertTrue(false, "***** Failed to remove Object(s)")
          }
          
        } else {
          Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
        }
        // disconnect the radio
        disconnect()
  }
  
  func testDaxMic() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "DaxMicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      for (_, object) in radio!.daxMicAudioStreams { object.remove() }
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
            let clientHandle = object.clientHandle
            
            Swift.print("***** Parameters saved")
            
            // remove all
            for (_, object) in radio!.daxMicAudioStreams { object.remove() }
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

                  // check params
                  XCTAssertEqual(object.clientHandle, clientHandle)
             
                  Swift.print("***** Parameters verified")
                  
                } else {
                  XCTAssertTrue(false, "\n***** 2nd Object NOT found *****\n")
                }
              } else {
                XCTAssertTrue(false, "\n***** 2nd Object NOT added *****\n")
              }
            } else {
              XCTAssertTrue(false, "\n***** 1st Object NOT removed *****\n")
            }
          } else {
            XCTAssertTrue(false, "\n***** 1st Object NOT found *****\n")
          }
        } else {
          XCTAssertTrue(false, "\n***** 1st Object NOT added *****\n")
        }
      } else {
        XCTAssertTrue(false, "\n***** Previous Object(s) NOT removed *****\n")
      }
      // remove
      for (_, object) in radio!.daxMicAudioStreams { object.remove() }
      
      Swift.print("***** Object(s) removed")
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
 }

  // ------------------------------------------------------------------------------
  // MARK: - DaxRxAudioStream

  // Format:  <streamId, > <"type", "dax_rx"> <"dax_channel", channel> <"slice", sliceLetter>  <"client_handle", handle> <"ip", ipAddress
  private var daxRxAudioStatus = "0x04000008 type=dax_rx dax_channel=2 slice=A ip=192.168.1.162"

  func testDaxRxAudioParse() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "DaxRxAudioStream.swift"))
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
          XCTAssertTrue(false, "***** Failed to create Object")
        }
      } else {
        XCTAssertTrue(false, "***** Failed to remove Object(s)")
      }
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testDaxRxAudio() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "DaxRxAudioStream.swift"))
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
                  XCTAssertTrue(false, "\n***** 2nd Object NOT found *****\n")
                }
              } else {
                XCTAssertTrue(false, "\n***** 2nd Object NOT added *****\n")
              }
            } else {
              XCTAssertTrue(false, "\n***** 1st Object NOT removed *****\n")
            }
          } else {
            XCTAssertTrue(false, "\n***** 1st Object NOT found *****\n")
          }
        } else {
          XCTAssertTrue(false, "\n***** 1st Object NOT added *****\n")
        }
      } else {
        XCTAssertTrue(false, "\n***** Previous Object(s) NOT removed *****\n")
      }
      // remove
      for (_, object) in radio!.daxRxAudioStreams { object.remove() }
      
      Swift.print("***** Object(s) removed")
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxTxAudioStream
  
  // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"tx", isTransmitChannel>
  private var daxTxAudioStatus = "0x0400000A type=dax_tx tx=1"
  
  func testDaxTxAudioParse() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "DaxTxAudioStream.swift"))
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
          XCTAssertTrue(false, "***** Failed to create Object")
        }
      } else {
        XCTAssertTrue(false, "***** Failed to remove Object(s)")
      }
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testDaxTxAudio() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "DaxTxAudioStream.swift"))
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
                  XCTAssert(true, "***** 2nd Object NOT found *****")
                }
              } else {
                XCTAssert(true, "***** 2nd Object NOT added *****")
              }
            } else {
              XCTAssert(true, "***** 1st Object NOT removed *****")
            }
          } else {
            XCTAssert(true, "***** 1st Object NOT found *****")
          }
        } else {
          XCTAssert(true, "***** 1st Object NOT added *****")
        }
      } else {
        XCTAssert(true, "***** Previous Object(s) NOT removed *****")
      }
      // remove any DaxTxAudioStream
      for (_, object) in radio!.daxTxAudioStreams { object.remove() }
      
      Swift.print("***** Object(s) removed")
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - MicAudioStream
  
  func testMicParse() {
            
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "MicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testMic() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "MicAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - TxAudioStream
  
  func testTxAudioParse() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "TxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
      } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }

  func testTxAudio() {
        
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: (true, "TxAudioStream.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("***** \(#function) NOT performed, incorrect version: radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch)")
    }
    // disconnect the radio
    disconnect()
  }
}
