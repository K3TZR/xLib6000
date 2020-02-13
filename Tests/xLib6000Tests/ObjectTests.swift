import XCTest
@testable import xLib6000

final class ObjectTests: XCTestCase {

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
 // MARK: - Amplifier
  
  ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
  private var amplifierStatus = "0x12345678 ant=ANT1 ip=10.0.1.106 model=PGXL port=4123 serial_num=1234-5678-9012 state=STANDBY"
  func testAmplifierParse() {

    let radio = discoverRadio()
    guard radio != nil else { return }

    Amplifier.parseStatus(radio!, amplifierStatus.keyValuesArray(), true)

    if let amplifier = radio!.amplifiers["0x12345678".streamId!] {
      // verify properties
      XCTAssertNotNil(amplifier, "Failed to create Amplifier")
      XCTAssertEqual(amplifier.id, "0x12345678".handle!)
      XCTAssertEqual(amplifier.ant, "ANT1")
      XCTAssertEqual(amplifier.ip, "10.0.1.106")
      XCTAssertEqual(amplifier.model, "PGXL")
      XCTAssertEqual(amplifier.port, 4123)
      XCTAssertEqual(amplifier.serialNumber, "1234-5678-9012")
      XCTAssertEqual(amplifier.state, "STANDBY")

      // change properties
      amplifier.ant = "ANT2"
      amplifier.ip = "11.1.217"
      amplifier.model = "QIYM"
      amplifier.port = 3214
      amplifier.serialNumber = "2109-8765-4321"
      amplifier.state = "IDLE"

      // re-verify properties
      XCTAssertEqual(amplifier.id, "0x12345678".handle!)
      XCTAssertEqual(amplifier.ant, "ANT2")
      XCTAssertEqual(amplifier.ip, "11.1.217")
      XCTAssertEqual(amplifier.model, "QIYM")
      XCTAssertEqual(amplifier.port, 3214)
      XCTAssertEqual(amplifier.serialNumber, "2109-8765-4321")
      XCTAssertEqual(amplifier.state, "IDLE")

    } else {
      XCTAssertTrue(false, "Failed to create Amplifier")
    }

    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testAmplifier() {
    
    Swift.print("\n***** \(#function) NOT implemented, NEED MORE INFORMATION ****\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - AudioStream
   
  ///   Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
  private var audioStreamStatus = "0x23456789 dax=3 slice=0 ip=10.0.1.107 port=4124"
  func testAudioStreamParse() {

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

  func testAudioStream() {
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
  // MARK: - BandSetting
  
  private var bandSettingStatus = "band 999 band_name=21 acc_txreq_enable=1 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=0 tx2_enabled=1 tx3_enabled=0"
  func testBandSettingParse() {
    
    let radio = discoverRadio()
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
        XCTAssertTrue(false, "\n***** Failed to create BandSetting *****\n")
      }

    }  else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testBandSetting() {
    
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
  // MARK: - DaxIqStream
  
    // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>
    private var daxIqStatus = "0x20000000 type=dax_iq daxiq_channel=3 pan=0x40000000 ip=10.0.1.107 daxiq_rate=48"
    func testDaxIqParse() {

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
      Api.sharedInstance.disconnect()
    }

  func testDaxIq() {
      // find a radio & connect
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
      Api.sharedInstance.disconnect()
    }

  // ------------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream
  
  func testDaxMicParse() {
    
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

  func testDaxMic() {
    
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
  
  func testDaxRxParse() {
    
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
  
  func testDaxRx() {
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
            //let daxClients = stream.daxClients
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
                  XCTAssertEqual(stream.daxClients, daxClients)
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
  
  func testDaxTxParse() {
    
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
  
  func testDaxTx() {
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
  // MARK: - Equalizer
   
  private var equalizerRxStatus = "rxsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  
  func testEqualizerRx() {
    equalizer(.rxsc)
  }
  func testEqualizerTx() {
    equalizer(.txsc)
  }

  func equalizer(_ type: Equalizer.EqType) {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if let eq = radio!.equalizers[type] {
      // save params
      let eqEnabled   = eq.eqEnabled
      let level63Hz   = eq.level63Hz
      let level125Hz  = eq.level125Hz
      let level250Hz  = eq.level250Hz
      let level500Hz  = eq.level500Hz
      let level1000Hz = eq.level1000Hz
      let level2000Hz = eq.level2000Hz
      let level4000Hz = eq.level4000Hz
      let level8000Hz = eq.level8000Hz
      
      // change params
      eq.eqEnabled = !eqEnabled
      eq.level63Hz    = 10
      eq.level125Hz   = -10
      eq.level250Hz   = 20
      eq.level500Hz   = -20
      eq.level1000Hz  = 30
      eq.level2000Hz  = -30
      eq.level4000Hz  = 40
      eq.level8000Hz  = -40

      // check params
      XCTAssertEqual(eq.eqEnabled, !eqEnabled)
      XCTAssertEqual(eq.level63Hz, 10)
      XCTAssertEqual(eq.level125Hz, -10)
      XCTAssertEqual(eq.level250Hz, 20)
      XCTAssertEqual(eq.level500Hz, -20)
      XCTAssertEqual(eq.level1000Hz, 30)
      XCTAssertEqual(eq.level2000Hz, -30)
      XCTAssertEqual(eq.level4000Hz, 40)
      XCTAssertEqual(eq.level8000Hz, -40)
      
      // restore params
      eq.eqEnabled    = eqEnabled
      eq.level63Hz    = level63Hz
      eq.level125Hz   = level125Hz
      eq.level250Hz   = level250Hz
      eq.level500Hz   = level500Hz
      eq.level1000Hz  = level1000Hz
      eq.level2000Hz  = level2000Hz
      eq.level4000Hz  = level4000Hz
      eq.level8000Hz  = level8000Hz

      // check params
      XCTAssertEqual(eq.eqEnabled, eqEnabled)
      XCTAssertEqual(eq.level63Hz, level63Hz)
      XCTAssertEqual(eq.level125Hz, level125Hz)
      XCTAssertEqual(eq.level250Hz, level250Hz)
      XCTAssertEqual(eq.level500Hz, level500Hz)
      XCTAssertEqual(eq.level1000Hz, level1000Hz)
      XCTAssertEqual(eq.level2000Hz, level2000Hz)
      XCTAssertEqual(eq.level4000Hz, level4000Hz)
      XCTAssertEqual(eq.level8000Hz, level8000Hz)
    
    } else {
      XCTAssert(true, "\n***** \(type.rawValue) Equalizer NOT found *****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - IqStream
  
  func testIqParse() {
    
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

  func testIq() {

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
    Api.sharedInstance.disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Memory
  
  func testMemoryParse() {
    
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

  func testMemory() {
    
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
  // MARK: - Meter
  
  func testMeterParse() {
    
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

  func testMeter() {
    
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
  // MARK: - Opus
  
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

  // ------------------------------------------------------------------------------
  // MARK: - Panadapter
   
  private let panadapterStatus = "pan 0x40000000 wnb=0 wnb_level=92 wnb_updating=0 band_zoom=0 segment_zoom=0 x_pixels=50 y_pixels=100 center=14.100000 bandwidth=0.200000 min_dbm=-125.00 max_dbm=-40.00 fps=25 average=23 weighted_average=0 rfgain=50 rxant=ANT1 wide=0 loopa=0 loopb=1 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 waterfall=42000000 min_bw=0.004920 max_bw=14.745601 xvtr= pre= ant_list=ANT1,ANT2,RX_A,XVTR"
  
  func removeAllPanadapters(radio: Radio) {

    for (_, panadapter) in radio.panadapters {
      for (_, slice) in radio.slices where slice.panadapterId == panadapter.id {
        slice.remove()
      }
      panadapter.remove()
    }
    sleep(1)
    XCTAssertTrue(radio.panadapters.count == 0, "\n***** Panadapter(s) NOT removed *****\n")
    XCTAssertTrue(radio.slices.count == 0, "\n***** Slice(s) NOT removed *****\n")
  }

  func testPanadapterParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    removeAllPanadapters(radio: radio!)
    
    Panadapter.parseStatus(radio!, panadapterStatus.keyValuesArray(), true)
    
    if let panadapter = radio!.panadapters["0x40000000".streamId!] {
      XCTAssertNotNil(panadapter, "\n***** Failed to create Panadapter *****\n")
      XCTAssertEqual(panadapter.wnbLevel, 92)
      XCTAssertEqual(panadapter.wnbUpdating, false)
      XCTAssertEqual(panadapter.bandZoomEnabled, false)
      XCTAssertEqual(panadapter.segmentZoomEnabled, false)
      XCTAssertEqual(panadapter.xPixels, 0)
      XCTAssertEqual(panadapter.yPixels, 0)
      XCTAssertEqual(panadapter.center, 14_100_000)
      XCTAssertEqual(panadapter.bandwidth, 200_000)
      XCTAssertEqual(panadapter.minDbm, -125.00)
      XCTAssertEqual(panadapter.maxDbm, -40.00)
      XCTAssertEqual(panadapter.fps, 25)
      XCTAssertEqual(panadapter.average, 23)
      XCTAssertEqual(panadapter.weightedAverageEnabled, false)
      XCTAssertEqual(panadapter.rfGain, 50)
      XCTAssertEqual(panadapter.rxAnt, "ANT1")
      XCTAssertEqual(panadapter.wide, false)
      XCTAssertEqual(panadapter.loopAEnabled, false)
      XCTAssertEqual(panadapter.loopBEnabled, true)
      XCTAssertEqual(panadapter.band, "20")
      XCTAssertEqual(panadapter.daxIqChannel, 0)
      XCTAssertEqual(panadapter.waterfallId, "0x42000000".streamId!)
      XCTAssertEqual(panadapter.minBw, 4_920)
      XCTAssertEqual(panadapter.maxBw, 14_745_601)
      XCTAssertEqual(panadapter.antList, ["ANT1","ANT2","RX_A","XVTR"])
    }
    removeAllPanadapters(radio: radio!)

    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testPanadapter() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {

      removeAllPanadapters(radio: radio!)
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      // verify added
      XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
      if let panadapter = radio!.panadapters[0] {
        
        // save params
        let wnbLevel = panadapter.wnbLevel
        let wnbUpdating = panadapter.wnbUpdating
        let bandZoomEnabled = panadapter.bandZoomEnabled
        let segmentZoomEnabled = panadapter.segmentZoomEnabled
        let xPixels = panadapter.xPixels
        let yPixels = panadapter.yPixels
        let center = panadapter.center
        let bandwidth = panadapter.bandwidth
        let minDbm = panadapter.minDbm
        let maxDbm = panadapter.maxDbm
        let fps = panadapter.fps
        let average = panadapter.average
        let weightedAverageEnabled = panadapter.weightedAverageEnabled
        let rfGain = panadapter.rfGain
        let rxAnt = panadapter.rxAnt
        let wide = panadapter.wide
        let loopAEnabled = panadapter.loopAEnabled
        let loopBEnabled = panadapter.loopBEnabled
        let band = panadapter.band
        let daxIqChannel = panadapter.daxIqChannel
        let waterfallId = panadapter.waterfallId
        let minBw = panadapter.minBw
        let maxBw = panadapter.maxBw
        let antList = panadapter.antList

        removeAllPanadapters(radio: radio!)
        
        // ask for newm
        radio!.requestPanadapter(frequency: 15_000_000)
        sleep(1)
        
        // verify added
        XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
        if let panadapter = radio!.panadapters[0] {
          
          // check params
          XCTAssertEqual(panadapter.wnbLevel, wnbLevel)
          XCTAssertEqual(panadapter.wnbUpdating, wnbUpdating)
          XCTAssertEqual(panadapter.bandZoomEnabled, bandZoomEnabled)
          XCTAssertEqual(panadapter.segmentZoomEnabled, segmentZoomEnabled)
          XCTAssertEqual(panadapter.xPixels, xPixels)
          XCTAssertEqual(panadapter.yPixels, yPixels)
          XCTAssertEqual(panadapter.center, center)
          XCTAssertEqual(panadapter.bandwidth, bandwidth)
          XCTAssertEqual(panadapter.minDbm, minDbm)
          XCTAssertEqual(panadapter.maxDbm, maxDbm)
          XCTAssertEqual(panadapter.fps, fps)
          XCTAssertEqual(panadapter.average, average)
          XCTAssertEqual(panadapter.weightedAverageEnabled, weightedAverageEnabled)
          XCTAssertEqual(panadapter.rfGain, rfGain)
          XCTAssertEqual(panadapter.rxAnt, rxAnt)
          XCTAssertEqual(panadapter.wide, wide)
          XCTAssertEqual(panadapter.loopAEnabled, loopAEnabled)
          XCTAssertEqual(panadapter.loopBEnabled, loopBEnabled)
          XCTAssertEqual(panadapter.band, band)
          XCTAssertEqual(panadapter.daxIqChannel, daxIqChannel)
          XCTAssertEqual(panadapter.waterfallId, waterfallId)
          XCTAssertEqual(panadapter.minBw, minBw)
          XCTAssertEqual(panadapter.maxBw, maxBw)
          XCTAssertEqual(panadapter.antList, antList)
        }
      }
      removeAllPanadapters(radio: radio!)
    
    } else if radio!.version.isV3 {
      removeAllPanadapters(radio: radio!)
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      // verify added
      XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
      if let panadapter = radio!.panadapters[0] {
        
        // save params
        let clientHandle = panadapter.clientHandle
        let wnbLevel = panadapter.wnbLevel
        let wnbUpdating = panadapter.wnbUpdating
        let bandZoomEnabled = panadapter.bandZoomEnabled
        let segmentZoomEnabled = panadapter.segmentZoomEnabled
        let xPixels = panadapter.xPixels
        let yPixels = panadapter.yPixels
        let center = panadapter.center
        let bandwidth = panadapter.bandwidth
        let minDbm = panadapter.minDbm
        let maxDbm = panadapter.maxDbm
        let fps = panadapter.fps
        let average = panadapter.average
        let weightedAverageEnabled = panadapter.weightedAverageEnabled
        let rfGain = panadapter.rfGain
        let rxAnt = panadapter.rxAnt
        let wide = panadapter.wide
        let loopAEnabled = panadapter.loopAEnabled
        let loopBEnabled = panadapter.loopBEnabled
        let band = panadapter.band
        let daxIqChannel = panadapter.daxIqChannel
        let waterfallId = panadapter.waterfallId
        let minBw = panadapter.minBw
        let maxBw = panadapter.maxBw
        let antList = panadapter.antList
        
        removeAllPanadapters(radio: radio!)
        
        // ask for newm
        radio!.requestPanadapter(frequency: 15_000_000)
        sleep(1)
        
        // verify added
        XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
        if let panadapter = radio!.panadapters[0] {
          
          // check params
          XCTAssertEqual(panadapter.clientHandle, clientHandle)
          XCTAssertEqual(panadapter.wnbLevel, wnbLevel)
          XCTAssertEqual(panadapter.wnbUpdating, wnbUpdating)
          XCTAssertEqual(panadapter.bandZoomEnabled, bandZoomEnabled)
          XCTAssertEqual(panadapter.segmentZoomEnabled, segmentZoomEnabled)
          XCTAssertEqual(panadapter.xPixels, xPixels)
          XCTAssertEqual(panadapter.yPixels, yPixels)
          XCTAssertEqual(panadapter.center, center)
          XCTAssertEqual(panadapter.bandwidth, bandwidth)
          XCTAssertEqual(panadapter.minDbm, minDbm)
          XCTAssertEqual(panadapter.maxDbm, maxDbm)
          XCTAssertEqual(panadapter.fps, fps)
          XCTAssertEqual(panadapter.average, average)
          XCTAssertEqual(panadapter.weightedAverageEnabled, weightedAverageEnabled)
          XCTAssertEqual(panadapter.rfGain, rfGain)
          XCTAssertEqual(panadapter.rxAnt, rxAnt)
          XCTAssertEqual(panadapter.wide, wide)
          XCTAssertEqual(panadapter.loopAEnabled, loopAEnabled)
          XCTAssertEqual(panadapter.loopBEnabled, loopBEnabled)
          XCTAssertEqual(panadapter.band, band)
          XCTAssertEqual(panadapter.daxIqChannel, daxIqChannel)
          XCTAssertEqual(panadapter.waterfallId, waterfallId)
          XCTAssertEqual(panadapter.minBw, minBw)
          XCTAssertEqual(panadapter.maxBw, maxBw)
          XCTAssertEqual(panadapter.antList, antList)
        }
      }
      removeAllPanadapters(radio: radio!)
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - RemoteRxAudioStream
  
  func testRemoteRxParse() {
    
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

  func testRemoteRx() {
    
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
  // MARK: - RemoteTxAudioStream
  
  func testRemoteTxParse() {
    
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

  func testRemoteTx() {
    
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
  // MARK: - Slice
  
  func testSliceParse() {
    
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

  func testSlice() {
    
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
  // MARK: - Tnf
   
  private var tnfStatus = "1 freq=14.26 depth=2 width=0.000100 permanent=1"
  func testTnfParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: ObjectId = tnfStatus.keyValuesArray()[0].key.objectId!
    Tnf.parseStatus(radio!, tnfStatus.keyValuesArray(), true)

    let tnf = radio!.tnfs[id]
    XCTAssertNotNil(tnf, "\n***** Failed to create Tnf")
    XCTAssertEqual(tnf?.depth, 2)
    XCTAssertEqual(tnf?.frequency, 14_260_000)
    XCTAssertEqual(tnf?.permanent, true)
    XCTAssertEqual(tnf?.width, 100)
    
    tnf?.remove()
    XCTAssertEqual(radio!.tnfs[id], nil, "\n***** Failed to remove Tnf *****\n")
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testTnf() {
    
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
  
  func testTxParse() {
    
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

  func testTx() {
    
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
  // MARK: - UsbCable
  
  func testUsbCableParse() {
    
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

  func testUsbCable() {
    
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
  // MARK: - Waterfall
     
  private var waterfallStatus = "waterfall 0x42000000 x_pixels=50 center=14.100000 bandwidth=0.200000 band_zoom=0 segment_zoom=0 line_duration=100 rfgain=0 rxant=ANT1 wide=0 loopa=0 loopb=0 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 panadapter=40000000 color_gain=50 auto_black=1 black_level=20 gradient_index=1 xvtr="
  func testWaterfallParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: StreamId = waterfallStatus.keyValuesArray()[1].key.streamId!
    Waterfall.parseStatus(radio!, waterfallStatus.keyValuesArray(), true)
    
    if let waterfallObject = radio!.waterfalls[id] {
      
      XCTAssertEqual(waterfallObject.autoBlackEnabled, true)
      XCTAssertEqual(waterfallObject.blackLevel, 20)
      XCTAssertEqual(waterfallObject.colorGain, 50)
      XCTAssertEqual(waterfallObject.gradientIndex, 1)
      XCTAssertEqual(waterfallObject.lineDuration, 100)
      XCTAssertEqual(waterfallObject.panadapterId, "0x40000000".streamId)

    } else {
        XCTAssertTrue(false, "\n***** Failed to create Waterfall *****\n")
    }
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testWaterfall() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")

    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Xvtr

  private var xvtrStatus = "0 name=220 rf_freq=220 if_freq=28 lo_error=0 max_power=10 rx_gain=0 order=0 rx_only=1 is_valid=1 preferred=1 two_meter_int=0"
  private var xvtrStatusLongName = "0 name=12345678 rf_freq=220 if_freq=28 lo_error=0 max_power=10 rx_gain=0 order=0 rx_only=1 is_valid=1 preferred=1 two_meter_int=0"

  func testXvtrParse() {
    xvtrCheck(status: xvtrStatus, expectedName: "220")
  }

  func testXvtrName() {
    // check that name is limited to 4 characters
    xvtrCheck(status: xvtrStatusLongName, expectedName: "1234")
  }

  func xvtrCheck(status: String, expectedName: String) {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: XvtrId = status.keyValuesArray()[0].key.objectId!
    Xvtr.parseStatus(radio!, status.keyValuesArray(), true)
    if let xvtrObject = radio!.xvtrs[id] {
      
      XCTAssertEqual(xvtrObject.ifFrequency, 28_000_000)
      XCTAssertEqual(xvtrObject.isValid, true)
      XCTAssertEqual(xvtrObject.loError, 0)
      XCTAssertEqual(xvtrObject.name, expectedName)
      XCTAssertEqual(xvtrObject.maxPower, 10)
      XCTAssertEqual(xvtrObject.order, 0)
      XCTAssertEqual(xvtrObject.preferred, true)
      XCTAssertEqual(xvtrObject.rfFrequency, 220_000_000)
      XCTAssertEqual(xvtrObject.rxGain, 0)
      XCTAssertEqual(xvtrObject.rxOnly, true)
    
      // FIXME: ??? what is this
      //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)

    } else {
      XCTAssertTrue(false, "\n***** Failed to create Xvtr *****\n")
    }

    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testXvtr() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    // remove all
    for (_, xvtrObject) in radio!.xvtrs { xvtrObject.remove() }
    sleep(1)
    if radio!.xvtrs.count == 0 {
            
      Swift.print("\n***** Previous Xvtr(s) removed ****\n")

      // ask for new
      radio!.requestXvtr()
      sleep(1)
      
      // verify added
      if radio!.xvtrs.count == 1 {
        
        if let xvtrObject = radio!.xvtrs["0".objectId!] {
          
          Swift.print("\n***** 1st Xvtr added ****\n")

          // set properties
          xvtrObject.ifFrequency = 28_000_000
          xvtrObject.loError = 0
          xvtrObject.name = "220"
          xvtrObject.maxPower = 10
          xvtrObject.order = 0
          xvtrObject.rfFrequency = 220_000_000
          xvtrObject.rxGain = 25
          xvtrObject.rxOnly = true
          
          // check params
          XCTAssertEqual(xvtrObject.isValid, false)
          XCTAssertEqual(xvtrObject.preferred, false)

          XCTAssertEqual(xvtrObject.ifFrequency, 28_000_000)
          XCTAssertEqual(xvtrObject.loError, 0)
          XCTAssertEqual(xvtrObject.name, "220")
          XCTAssertEqual(xvtrObject.maxPower, 10)
          XCTAssertEqual(xvtrObject.order, 0)
          XCTAssertEqual(xvtrObject.rfFrequency, 220_000_000)
          XCTAssertEqual(xvtrObject.rxGain, 25)
          XCTAssertEqual(xvtrObject.rxOnly, true)
          
          // FIXME: ??? what is this
          //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
          
          // ask for a new AudioStream
          radio!.requestXvtr()
          sleep(1)
          
          // verify added
          if radio!.xvtrs.count == 2 {
            
            if let xvtrObject = radio!.xvtrs["1".objectId!] {
              
              Swift.print("\n***** 2nd Xvtr added ****\n")
              
              // set properties
              xvtrObject.ifFrequency = 14_000_000
              xvtrObject.loError = 1
              xvtrObject.name = "144"
              xvtrObject.maxPower = 20
              xvtrObject.order = 1
              xvtrObject.rfFrequency = 144_000_000
              xvtrObject.rxGain = 50
              xvtrObject.rxOnly = false
              
              // verify properties
              XCTAssertEqual(xvtrObject.isValid, false)
              XCTAssertEqual(xvtrObject.preferred, false)

              XCTAssertEqual(xvtrObject.ifFrequency, 14_000_000)
              XCTAssertEqual(xvtrObject.loError, 1)
              XCTAssertEqual(xvtrObject.name, "144")
              XCTAssertEqual(xvtrObject.maxPower, 20)
              XCTAssertEqual(xvtrObject.order, 1)
              XCTAssertEqual(xvtrObject.rfFrequency, 144_000_000)
              XCTAssertEqual(xvtrObject.rxGain, 50)
              XCTAssertEqual(xvtrObject.rxOnly, false)
              
              // FIXME: ??? what is this
              //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
            } else {
              XCTAssertTrue(false, "\n***** Xvtr 1 NOT found *****\n")
            }
          } else {
            XCTAssertTrue(false, "\n***** Xvtr 1 NOT added *****\n")
          }
          
        } else {
          XCTAssertTrue(false, "\n***** Xvtr 0 NOT found *****\n")
        }
      } else {
        XCTAssertTrue(false, "\n***** Xvtr 0 NOT added *****\n")
      }
    } else {
      XCTAssertTrue(false, "\n***** Xvtr(s) NOT removed *****\n")
    }
    // remove all
    for (_, xvtrObject) in radio!.xvtrs { xvtrObject.remove() }
          
    Swift.print("\n***** Added Xvtr(s) removed ****\n")

    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

//  static var allTests = [
//    ("testApi", testApi),
//    ("testLog", testLog),
//    ("testDiscovery", testDiscovery),
//    ("testRadio", testRadio),
//
//    ("testEqualizerRx", testEqualizerRx),
//    ("testEqualizerTx", testEqualizerTx),
//    ("testPanadapter", testPanadapter),
//    ("testTnf", testTnf),
//    ("testWaterfall", testWaterfall),
//    ("testXvtr1", testXvtr1),
//    ("testXvtr2", testXvtr2)
//  ]
}
