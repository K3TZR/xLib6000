//
//  File.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class IqTests: XCTestCase {
  
  // Helper function
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "IqTests", logState: logState) {
        sleep(1)
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
  // MARK: - DaxIqStream
  
  // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>
  private var daxIqStatus = "0x20000000 type=dax_iq daxiq_channel=3 pan=0x40000000 ip=10.0.1.107 daxiq_rate=48"
  func testDaxIqParse() {
        
    Swift.print("\n***** \(#function)")
    
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
        XCTAssertTrue(false, "\n***** Failed to create DaxIqStream *****\n")
      }

    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

func testDaxIq() {
        
    Swift.print("\n***** \(#function)")
    
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
                    XCTAssertFalse(true, "\n***** DaxIqStream NOT removed *****\n")
                  }
                } else {
                  XCTAssertFalse(true, "\n***** DaxIqStream 0 NOT found *****\n")
                }
              } else {
                XCTAssertFalse(true, "\n***** DaxIqStream NOT added *****\n")
              }
            } else {
              XCTAssertFalse(true, "\n***** DaxIqStream NOT removed *****\n")
            }
          } else {
            XCTAssertFalse(true, "\n***** DaxIqStream 0 NOT found *****\n")
          }
        } else {
          XCTAssertFalse(true, "\n***** DaxIqStream NOT added *****\n")
        }
      } else {
        XCTAssertFalse(true, "\n***** DaxIqStream NOT removed *****\n")
      }
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }
}
