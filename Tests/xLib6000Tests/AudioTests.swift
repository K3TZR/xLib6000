//
//  AudioTests.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class DaxTests: XCTestCase {
  
  // Helper function
  func discoverRadio() -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "xLib6000Tests") {
        sleep(1)
        return Api.sharedInstance.radio
      } else {
        XCTAssertTrue(false, "\n***** Failed to connect to Radio *****\n")
        return nil
      }
    } else {
      XCTAssertTrue(false, "\n***** No Radio(s) found *****\n")
      return nil
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - AudioStream
   
  ///   Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
  private var audioStreamStatus = "0x23456789 dax=3 slice=0 ip=10.0.1.107 port=4124"
  func testAudioParse() {

    let radio = discoverRadio()
    guard radio != nil else { return }

    if radio!.version.isV1 || radio!.version.isV2 {

      radio!.requestAudioStream("2")
      sleep(1)

      if let audioStream = radio!.audioStreams["0x23456789".streamId!] {
        // verify properties
        XCTAssertEqual(audioStream.id, "0x23456789".streamId)
        XCTAssertEqual(audioStream.daxChannel, 3)
        XCTAssertEqual(audioStream.ip, "10.0.1.107")
        XCTAssertEqual(audioStream.port, 4124)
        XCTAssertEqual(audioStream.slice, radio!.slices["0".objectId!])

        // change properties
        audioStream.daxChannel = 4
        audioStream.ip = "12.2.3.218"
        audioStream.port = 4214
        audioStream.slice = radio!.slices["0".objectId!]

        // re-verify properties
        XCTAssertEqual(audioStream.id, "0x23456789".streamId)
        XCTAssertEqual(audioStream.daxChannel, 4)
        XCTAssertEqual(audioStream.ip, "12.2.3.218")
        XCTAssertEqual(audioStream.port, 4214)
        XCTAssertEqual(audioStream.slice, radio!.slices["0".objectId!])

        // remove
        audioStream.remove()
        sleep(1)
        XCTAssert(radio!.audioStreams["0x23456789".streamId!] == nil, "\n***** Failed to remove AudioStream *****\n")

      } else {
        XCTAssertTrue(false, "\n***** Failed to create AudioStream *****\n")
      }

    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testAudio() {
    // find a radio & connect
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {     // v1 and v2 ONLY
      
      // remove any AudioStreams
      for (_, stream) in radio!.audioStreams { stream.remove() }
      sleep(1)
      if radio!.audioStreams.count == 0 {
        
        // ask for a new AudioStream
        radio!.requestAudioStream( "2")
        sleep(1)
        
        // verify AudioStream added
        if radio!.audioStreams.count == 1 {
          
          if let stream = radio!.audioStreams[0] {
            
            // save params
            let daxChannel = stream.daxChannel
            let ip = stream.ip
            let port = stream.port
            let slice = stream.slice
            
            // remove any AudioStreams
            for (_, stream) in radio!.audioStreams { stream.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              // ask for a new AudioStream
              radio!.requestAudioStream( "2")
              sleep(1)
              
              // verify AudioStream added
              if radio!.audioStreams.count == 1 {
                if let audioStreamObject = radio!.audioStreams[0] {
                  
                  // check params
                  XCTAssertEqual(audioStreamObject.id, "0x23456789".streamId)
                  XCTAssertEqual(audioStreamObject.daxChannel, daxChannel)
                  XCTAssertEqual(audioStreamObject.ip, ip)
                  XCTAssertEqual(audioStreamObject.port, port)
                  XCTAssertEqual(audioStreamObject.slice, slice)
                  
                  // change properties
                  audioStreamObject.daxChannel = 4
                  audioStreamObject.ip = "12.2.3.218"
                  audioStreamObject.port = 4214
                  audioStreamObject.slice = radio!.slices["0".objectId!]

                  // re-verify properties
                  XCTAssertEqual(audioStreamObject.id, "0x23456789".streamId)
                  XCTAssertEqual(audioStreamObject.daxChannel, 4)
                  XCTAssertEqual(audioStreamObject.ip, "12.2.3.218")
                  XCTAssertEqual(audioStreamObject.port, 4214)
                  XCTAssertEqual(audioStreamObject.slice, radio!.slices["0".objectId!])

                } else {
                  XCTAssert(true, "\n***** AudioStream 0 NOT found *****\n")
                }
              } else {
                XCTAssert(true, "\n***** AudioStream(s) NOT added *****\n")
              }
            } else {
              XCTAssert(true, "\n***** AudioStream(s) NOT removed *****\n")
            }
          } else {
            XCTAssert(true, "\n***** AudioStream 0 NOT found *****\n")
          }
        } else {
          XCTAssert(true, "\n***** AudioStream(s) NOT added *****\n")
        }
      } else {
        XCTAssert(true, "\n***** AudioStream(s) NOT removed *****\n")
      }
      // remove any AudioStreams
      for (_, stream) in radio!.audioStreams { stream.remove() }
    
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream
  
  func testDaxMicAudioParse() {
    
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
  
  func testDaxMicAudio() {
    
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
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxRxAudioStream
  
  func testDaxRxAudioParse() {
    
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
  
  func testDaxRxAudio() {
    // find a radio & connect
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove any DaxRxAudioStreams
      for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
      sleep(1)
      if radio!.daxRxAudioStreams.count == 0 {
        
        // ask for a new DaxRxAudioStream
        radio!.requestDaxRxAudioStream( "2")
        sleep(1)
        
        // verify DaxRxAudioStream added
        if radio!.daxRxAudioStreams.count == 1 {
          
          if let stream = radio!.daxRxAudioStreams[0] {
            
            // save params
            let clientHandle = stream.clientHandle
            let daxChannel = stream.daxChannel
//            let daxClients = stream.daxClients
            let slice = stream.slice
            
            // remove any DaxRxAudioStreams
            for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              // ask for a new DaxRxAudioStream
              radio!.requestDaxRxAudioStream( "2")
              sleep(1)
              
              // verify DaxRxAudioStream added
              if radio!.daxRxAudioStreams.count == 1 {
                if let stream = radio!.daxRxAudioStreams[0] {
                  
                  // check params
                  XCTAssertEqual(stream.clientHandle, clientHandle)
                  XCTAssertEqual(stream.daxChannel, daxChannel)
//                  XCTAssertEqual(stream.daxClients, daxClients)
                  XCTAssertEqual(stream.slice, slice)
                  
                } else {
                  XCTAssert(true, "\n***** DaxRxAudioStream 0 NOT found *****\n")
                }
              } else {
                XCTAssert(true, "\n***** DaxRxAudioStream NOT added *****\n")
              }
            } else {
              XCTAssert(true, "\n***** DaxRxAudioStream NOT removed *****\n")
            }
          } else {
            XCTAssert(true, "\n***** DaxRxAudioStream 0 NOT found *****\n")
          }
        } else {
          XCTAssert(true, "\n***** DaxRxAudioStream NOT added *****\n")
        }
      } else {
        XCTAssert(true, "\n***** DaxRxAudioStream NOT removed *****\n")
      }
      // remove any DaxRxAudioStream
      for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - DaxTxAudioStream
  
  func testDaxTxAudioParse() {
    
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
  
  func testDaxTxAudio() {
    // find a radio & connect
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      
      // remove all
      for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
      sleep(1)
      if radio!.daxTxAudioStreams.count == 0 {
        
        // get new
        radio!.requestDaxTxAudioStream()
        sleep(1)
        
        // verify added
        if radio!.daxTxAudioStreams.count == 1 {
          
          if let stream = radio!.daxTxAudioStreams[0] {
            
            // save params
            let clientHandle = stream.clientHandle
            let isTransmitChannel = stream.isTransmitChannel
            
            // remove all
            for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
            sleep(1)
            if radio!.audioStreams.count == 0 {
              
              // get new
              radio!.requestDaxTxAudioStream()
              sleep(1)
              
              // verify added
              if radio!.daxTxAudioStreams.count == 1 {
                if let stream = radio!.daxTxAudioStreams[0] {
                  
                  // check params
                  XCTAssertEqual(stream.clientHandle, clientHandle)
                  XCTAssertEqual(stream.isTransmitChannel, isTransmitChannel)
                  
                } else {
                  XCTAssert(true, "\n***** DaxTxAudioStream 0 NOT found *****\n")
                }
              } else {
                XCTAssert(true, "\n***** DaxTxAudioStream NOT added *****\n")
              }
            } else {
              XCTAssert(true, "\n***** DaxTxAudioStream NOT removed *****\n")
            }
          } else {
            XCTAssert(true, "\n***** DaxTxAudioStream 0 NOT found *****\n")
          }
        } else {
          XCTAssert(true, "\n***** DaxTxAudioStream NOT added *****\n")
        }
      } else {
        XCTAssert(true, "\n***** DaxTxAudioStream NOT removed *****\n")
      }
      // remove any DaxTxAudioStream
      for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - MicAudioStream
  
  func testMicParse() {
    
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
  
  func testMic() {
    
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
  
  // ------------------------------------------------------------------------------
  // MARK: - TxAudioStream
  
  func testTxAudioParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
      } else if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testTxAudio() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
}
