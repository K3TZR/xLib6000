import XCTest
@testable import xLib6000

final class xLib6000Tests: XCTestCase {
 
  func testApi() {
    let api = Api.sharedInstance
    XCTAssertNotNil(api, "Api singleton not present")
    XCTAssertNotNil(api.tcp, "Failed to instantiate TcpManager")
    XCTAssertNotNil(api.udp, "Failed to instantiate UdpManager")
  }
  
  func testLog() {
    let log = Log.sharedInstance
    XCTAssertNotNil(log, "Log singleton not present")
  }

  func testDiscovery() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    XCTAssertGreaterThan(discovery.discoveredRadios.count, 0, "No Radios discovered")
  }
  
  func testObjectCreation() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")

    XCTAssertNotNil(radio.atu, "Failed to instantiate Atu")
    XCTAssertNotNil(radio.cwx, "Failed to instantiate Cwx")
    XCTAssertNotNil(radio.gps, "Failed to instantiate Gps")
    XCTAssertNotNil(radio.interlock, "Failed to instantiate Interlock")
    XCTAssertNotNil(radio.transmit, "Failed to instantiate Transmit")
    XCTAssertNotNil(radio.wan, "Failed to instantiate Wan")
    XCTAssertNotNil(radio.waveform, "Failed to instantiate Waveform")
    
    let amplifier = Amplifier(radio: radio, id: "0x1234abcd".streamId!)
    XCTAssertNotNil(amplifier, "Failed to instantiate Amplifier")

    let audioStream = AudioStream(radio: radio, id: "0x41000000".streamId!)
    XCTAssertNotNil(audioStream, "Failed to instantiate AudioStream")
    
    let daxIqStream = DaxIqStream(radio: radio, id: 1)
    XCTAssertNotNil(daxIqStream, "Failed to instantiate DaxIqStream")

    let daxMicAudioStream = DaxMicAudioStream(radio: radio, id: "0x42000000".streamId!)
    XCTAssertNotNil(daxMicAudioStream, "Failed to instantiate DaxMicAudioStream")

    let daxRxAudioStream = DaxRxAudioStream(radio: radio, id: "0x43000000".streamId!)
    XCTAssertNotNil(daxRxAudioStream, "Failed to instantiate DaxRxAudioStream")

    let daxTxAudioStream = DaxTxAudioStream(radio: radio, id: "0x44000000".streamId!)
    XCTAssertNotNil(daxTxAudioStream, "Failed to instantiate DaxTxAudioStream")

    let rxEqualizer = Equalizer(radio: radio, id: "rxsc")
    XCTAssertNotNil(rxEqualizer, "Failed to instantiate Rx Equalizer")

    let txEqualizer = Equalizer(radio: radio, id: "txsc")
    XCTAssertNotNil(txEqualizer, "Failed to instantiate Tx Equalizer")

    let iqStream = IqStream(radio: radio, id: 1)
    XCTAssertNotNil(iqStream, "Failed to instantiate IqStream")

    let memory = Memory(radio: radio, id: "0")
    XCTAssertNotNil(memory, "Failed to instantiate Memory")

    let meter = Meter(radio: radio, id: 1)
    XCTAssertNotNil(meter, "Failed to instantiate Meter")

    let micAudioStream = MicAudioStream(radio: radio, id: "0x45000000".streamId!)
    XCTAssertNotNil(micAudioStream, "Failed to instantiate MicAudioStream")

    let opus = Opus(radio: radio, id: "0x46000000".streamId!)
    XCTAssertNotNil(opus, "Failed to instantiate Opus")

    let pan = Panadapter(radio: radio, id: "0x40000000".streamId!)
    XCTAssertNotNil(pan, "Failed to instantiate Panadapter")

    let globalProfile = Profile(radio: radio, id: "global")
    XCTAssertNotNil(globalProfile, "Failed to instantiate Global Profile")

    let micProfile = Profile(radio: radio, id: "mic")
    XCTAssertNotNil(micProfile, "Failed to instantiate Mic Profile")

    let txProfile = Profile(radio: radio, id: "tx")
    XCTAssertNotNil(txProfile, "Failed to instantiate Tx Profile")

    let remoteRxAudioStream = RemoteRxAudioStream(radio: radio, id: "0x47000000".streamId!)
    XCTAssertNotNil(remoteRxAudioStream, "Failed to instantiate RemoteRxAudioStream")

    let remoteTxAudioStream = RemoteTxAudioStream(radio: radio, id: "0x48000000".streamId!)
    XCTAssertNotNil(remoteTxAudioStream, "Failed to instantiate RemoteTxAudioStream")

    let slice = Slice(radio: radio, id: "1".objectId!)
    XCTAssertNotNil(slice, "Failed to instantiate Slice")

    let tnf = Tnf(radio: radio, id: 1)
    XCTAssertNotNil(tnf, "Failed to instantiate Tnf")

    let txAudioStream = TxAudioStream(radio: radio, id: "0x49000000".streamId!)
    XCTAssertNotNil(txAudioStream, "Failed to instantiate TxAudioStream")

    let usbCableBcd = UsbCable(radio: radio, id: "abcd", cableType: .bcd)
    XCTAssertNotNil(usbCableBcd, "Failed to instantiate BCD UsbCable")

    let usbCableBit = UsbCable(radio: radio, id: "defg", cableType: .bit)
    XCTAssertNotNil(usbCableBit, "Failed to instantiate BIT UsbCable")

    let usbCableCat = UsbCable(radio: radio, id: "hijk", cableType: .cat)
    XCTAssertNotNil(usbCableCat, "Failed to instantiate CAT UsbCable")

    let usbCableDstar = UsbCable(radio: radio, id: "lmno", cableType: .dstar)
    XCTAssertNotNil(usbCableDstar, "Failed to instantiate DSTAR UsbCable")

    let usbCableLdpa = UsbCable(radio: radio, id: "pqrs", cableType: .ldpa)
    XCTAssertNotNil(usbCableLdpa, "Failed to instantiate LDPA UsbCable")

    let waterfall = Waterfall(radio: radio, id: "0x40000001".streamId!)
    XCTAssertNotNil(waterfall, "Failed to instantiate Waterfall")

    let xvtr = Xvtr(radio: radio, id: "abcd")
    XCTAssertNotNil(xvtr, "Failed to instantiate Xvtr")
  }

  // Helper function
  func discoverRadio() -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "xLib6000Tests") {
        sleep(1)
        return Api.sharedInstance.radio
      } else {
        XCTAssertTrue(false, "Failed to connect to Radio")
        return nil
      }
    } else {
      XCTAssertTrue(false, "No Radio(s) found")
      return nil
    }
  }
  
  func removeAllPanadapters(radio: Radio) {

    for (_, panadapter) in radio.panadapters {
      for (_, slice) in radio.slices where slice.panadapterId == panadapter.id {
        slice.remove()
      }
      panadapter.remove()
    }
    sleep(1)
    XCTAssertTrue(radio.panadapters.count == 0, "Panadapter(s) NOT removed")
    XCTAssertTrue(radio.slices.count == 0, "Slice(s) NOT removed")
  }

  func removeAllAudioStreams(radio: Radio) {

    for (_, stream) in radio.audioStreams {
      stream.remove()
    }
    sleep(1)
    XCTAssertTrue(radio.audioStreams.count == 0, "AudioStream(s) NOT removed")
  }

 // MARK: ---- Amplifier ----
  
  ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
//  private var amplifierStatus = "0x12345678 ant=ANT1 ip=10.0.1.106 model=PGXL port=4123 serial_num=1234-5678-9012 state=STANDBY"
//  func testAmplifierParse() {
//
//    let radio = discoverRadio()
//    guard radio != nil else { return }
//
//    Amplifier.parseStatus(radio!, amplifierStatus.keyValuesArray(), true)
//
//    if let amplifier = radio!.amplifiers["0x12345678".streamId!] {
//      // verify properties
//      XCTAssertNotNil(amplifier, "Failed to create Amplifier")
//      XCTAssertEqual(amplifier.id, "0x12345678".handle!)
//      XCTAssertEqual(amplifier.ant, "ANT1")
//      XCTAssertEqual(amplifier.ip, "10.0.1.106")
//      XCTAssertEqual(amplifier.model, "PGXL")
//      XCTAssertEqual(amplifier.port, 4123)
//      XCTAssertEqual(amplifier.serialNumber, "1234-5678-9012")
//      XCTAssertEqual(amplifier.state, "STANDBY")
//
//      // change properties
//      amplifier.ant = "ANT2"
//      amplifier.ip = "11.1.217"
//      amplifier.model = "QIYM"
//      amplifier.port = 3214
//      amplifier.serialNumber = "2109-8765-4321"
//      amplifier.state = "IDLE"
//
//      // re-verify properties
//      XCTAssertEqual(amplifier.id, "0x12345678".handle!)
//      XCTAssertEqual(amplifier.ant, "ANT2")
//      XCTAssertEqual(amplifier.ip, "11.1.217")
//      XCTAssertEqual(amplifier.model, "QIYM")
//      XCTAssertEqual(amplifier.port, 3214)
//      XCTAssertEqual(amplifier.serialNumber, "2109-8765-4321")
//      XCTAssertEqual(amplifier.state, "IDLE")
//
//      // remove
//      amplifier.remove()
//      sleep(1)
//      XCTAssert(radio!.amplifiers["0x12345678".streamId!] == nil, "Failed to remove Amplifier")
//
//    } else {
//      XCTAssertTrue(false, "Failed to create Amplifier")
//    }
//
//    // disconnect the radio
//    Api.sharedInstance.disconnect()
//  }

  // MARK: ---- AudioStream ----
   
  ///   Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
  private var audioStreamStatus = "0x23456789 dax=3 slice=0 ip=10.0.1.107 port=4124"
//  func testAudioStreamParse() {
//
//    let radio = discoverRadio()
//    guard radio != nil else { return }
//
//    if radio!.version.isV1 || radio!.version.isV2 {
//
//      radio!.requestAudioStream("2")
//      sleep(1)
//
//      if let audioStream = radio!.audioStreams["0x23456789".streamId!] {
//        // verify properties
//        XCTAssertEqual(audioStream.id, "0x23456789".streamId)
//        XCTAssertEqual(audioStream.daxChannel, 3)
//        XCTAssertEqual(audioStream.ip, "10.0.1.107")
//        XCTAssertEqual(audioStream.port, 4124)
//        XCTAssertEqual(audioStream.slice, radio!.slices["0".objectId!])
//
//        // change properties
//        audioStream.daxChannel = 4
//        audioStream.ip = "12.2.3.218"
//        audioStream.port = 4214
//        audioStream.slice = radio!.slices["0".objectId!]
//
//        // re-verify properties
//        XCTAssertEqual(audioStream.id, "0x23456789".streamId)
//        XCTAssertEqual(audioStream.daxChannel, 4)
//        XCTAssertEqual(audioStream.ip, "12.2.3.218")
//        XCTAssertEqual(audioStream.port, 4214)
//        XCTAssertEqual(audioStream.slice, radio!.slices["0".objectId!])
//
//        // remove
//        audioStream.remove()
//        sleep(1)
//        XCTAssert(radio!.audioStreams["0x23456789".streamId!] == nil, "Failed to remove AudioStream")
//
//      } else {
//        XCTAssertTrue(false, "Failed to create AudioStream")
//      }
//
//    } else {
//      // V3 - test not applicable
//    }
//    // disconnect the radio
//    Api.sharedInstance.disconnect()
//  }

  func testAudioStream() {
    // find a radio & connect
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
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
                if let stream = radio!.audioStreams[0] {
                  
                  // check params
                  XCTAssertEqual(stream.id, "0x23456789".streamId)
                  XCTAssertEqual(stream.daxChannel, daxChannel)
                  XCTAssertEqual(stream.ip, ip)
                  XCTAssertEqual(stream.port, port)
                  XCTAssertEqual(stream.slice, slice)
                
                } else {
                  XCTAssert(true, "AudioStream 0 NOT found")
                  for (_, stream) in radio!.audioStreams { stream.remove() }
                  return
                }
              
              } else {
                XCTAssert(true, "AudioStream(s) NOT added")
                for (_, stream) in radio!.audioStreams { stream.remove() }
                return
              }
            
            } else {
              for (_, stream) in radio!.audioStreams { stream.remove() }
              XCTAssert(true, "AudioStream(s) NOT removed")
              return
            }
            
          } else {
            XCTAssert(true, "AudioStream 0 NOT found")
            for (_, stream) in radio!.audioStreams { stream.remove() }
            return
          }
        
        } else {
          XCTAssert(true, "AudioStream(s) NOT added")
          for (_, stream) in radio!.audioStreams { stream.remove() }
          return
        }
      
      } else {
        for (_, stream) in radio!.audioStreams { stream.remove() }
        XCTAssert(true, "AudioStream(s) NOT removed")
        return
      }
      // remove any AudioStreams
      for (_, stream) in radio!.audioStreams { stream.remove() }
    
    } else {
      Swift.print("***** Test NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor) ****")
    }
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }
  
  // MARK: ---- DaxRxAudioStream ----
   
  func testDaxRxAudioStream() {
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
            let daxClients = stream.daxClients
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
                  XCTAssert(true, "DaxRxAudioStream 0 NOT found")
                  for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
                  return
                }
              
              } else {
                XCTAssert(true, "DaxRxAudioStream(s) NOT added")
                for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
                return
              }
            
            } else {
              for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
              XCTAssert(true, "DaxRxAudioStream(s) NOT removed")
              return
            }
            
          } else {
            XCTAssert(true, "DaxRxAudioStream 0 NOT found")
            for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
            return
          }
        
        } else {
          XCTAssert(true, "DaxRxAudioStream(s) NOT added")
          for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
          return
        }
      
      } else {
        for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
        XCTAssert(true, "DaxRxAudioStream(s) NOT removed")
        return
      }
      // remove any DaxRxAudioStream
      for (_, stream) in radio!.daxRxAudioStreams { stream.remove() }
    
    } else {
      Swift.print("***** DaxRxAudioStream Test NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor) ****")
    }
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // MARK: ---- DaxTxAudioStream ----
  
  func testDaxTxAudioStream() {
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
                  XCTAssert(true, "DaxTxAudioStream 0 NOT found")
                  for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
                  return
                }
              
              } else {
                XCTAssert(true, "DaxTxAudioStream(s) NOT added")
                for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
                return
              }
            
            } else {
              for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
              XCTAssert(true, "DaxTxAudioStream(s) NOT removed")
              return
            }
            
          } else {
            XCTAssert(true, "DaxTxAudioStream 0 NOT found")
            for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
            return
          }
        
        } else {
          XCTAssert(true, "DaxTxAudioStream(s) NOT added")
          for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
          return
        }
      
      } else {
        for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
        XCTAssert(true, "DaxTxAudioStream(s) NOT removed")
        return
      }
      // remove any DaxTxAudioStream
      for (_, stream) in radio!.daxTxAudioStreams { stream.remove() }
    
    } else {
      Swift.print("***** DaxTxAudioStream Test NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor) ****")
    }
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // MARK: ---- Rx Equalizer ----
   
  private var equalizerRxStatus = "rxsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  func testEqualizerRxParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let eqType = Equalizer.EqType(rawValue:equalizerRxStatus.keyValuesArray()[0].key)!

    Equalizer.parseStatus(radio!, equalizerRxStatus.keyValuesArray(), true)

    let eqRx = radio!.equalizers[eqType]
    XCTAssertNotNil(eqRx, "Failed to create Rx Equalizer")
    XCTAssertEqual(eqRx?.eqEnabled, false)
    XCTAssertEqual(eqRx?.level63Hz, 0)
    XCTAssertEqual(eqRx?.level125Hz, 10)
    XCTAssertEqual(eqRx?.level250Hz, 20)
    XCTAssertEqual(eqRx?.level500Hz, 30)
    XCTAssertEqual(eqRx?.level1000Hz, -10)
    XCTAssertEqual(eqRx?.level2000Hz, -20)
    XCTAssertEqual(eqRx?.level4000Hz, -30)
    XCTAssertEqual(eqRx?.level8000Hz, -40)
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // MARK: ---- Tx Equalizer ----
   
  private var equalizerTxStatus = "txsc mode=1 63Hz=-40 125Hz=-30 250Hz=-20 500Hz=-10 1000Hz=30 2000Hz=20 4000Hz=10 8000Hz=0"
  func testEqualizerTxParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let eqType = Equalizer.EqType(rawValue:equalizerTxStatus.keyValuesArray()[0].key)!

    Equalizer.parseStatus(radio!, equalizerTxStatus.keyValuesArray(), true)

    let eqTx = radio!.equalizers[eqType]
    XCTAssertNotNil(eqTx, "Failed to create Tx Equalizer")
    XCTAssertEqual(eqTx?.eqEnabled, true)
    XCTAssertEqual(eqTx?.level63Hz, -40)
    XCTAssertEqual(eqTx?.level125Hz, -30)
    XCTAssertEqual(eqTx?.level250Hz, -20)
    XCTAssertEqual(eqTx?.level500Hz, -10)
    XCTAssertEqual(eqTx?.level1000Hz, 30)
    XCTAssertEqual(eqTx?.level2000Hz, 20)
    XCTAssertEqual(eqTx?.level4000Hz, 10)
    XCTAssertEqual(eqTx?.level8000Hz, 0)
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // MARK: ---- Panadapter ----
   
  private let panadapterStatus = "pan 0x40000000 wnb=0 wnb_level=92 wnb_updating=0 band_zoom=0 segment_zoom=0 x_pixels=50 y_pixels=100 center=14.100000 bandwidth=0.200000 min_dbm=-125.00 max_dbm=-40.00 fps=25 average=23 weighted_average=0 rfgain=50 rxant=ANT1 wide=0 loopa=0 loopb=1 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 waterfall=42000000 min_bw=0.004920 max_bw=14.745601 xvtr= pre= ant_list=ANT1,ANT2,RX_A,XVTR"
  func testPanadapterParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    removeAllPanadapters(radio: radio!)
    
    Panadapter.parseStatus(radio!, panadapterStatus.keyValuesArray(), true)
    
    if let panadapter = radio!.panadapters["0x40000000".streamId!] {
      XCTAssertNotNil(panadapter, "Failed to create Panadapter")
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

  func testPanadapterCreateRemove() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {

      removeAllPanadapters(radio: radio!)
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      // verify added
      XCTAssertNotEqual(radio!.panadapters.count, 0, "No Panadapter")
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
        XCTAssertNotEqual(radio!.panadapters.count, 0, "No Panadapter")
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
      XCTAssertNotEqual(radio!.panadapters.count, 0, "No Panadapter")
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
        XCTAssertNotEqual(radio!.panadapters.count, 0, "No Panadapter")
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

//  func testPanadapterCreateRemove() {
//    // find a radio & connect
//    let radio = discoverRadio()
//    guard radio != nil else { return }
//
//    // remove any panadapters & slices
//    removeAllPanadapters(radio: radio!)
//
//    // ask for a new panadapter
//    radio!.requestPanadapter(frequency: 7_250_000)
//    sleep(1)
//
//    // verify panadapter added
//    XCTAssertNotEqual(radio!.panadapters.count, 0, "No Panadapter")
//    if let panadapter = radio!.panadapters[0] {
//
//      // save panadapter params
//      let center = panadapter.center
//      let bandwidth = panadapter.bandwidth
//
//      // verify slice added
//      XCTAssertNotEqual(radio!.slices.count, 0, "No Slice")
//
//      // save slice params
//      let sliceFrequency = radio!.slices[0]!.frequency
//
//      // remove any panadapters & slices
//      removeAllPanadapters(radio: radio!)
//
//      // ask for a new panadapter
//      radio!.requestPanadapter(frequency: 7_250_000)
//      sleep(1)
//
//      // verify panadapter added
//      XCTAssertNotEqual(radio!.panadapters.count, 0, "No Panadapter")
//      if let panadapter2 = radio!.panadapters[0] {
//
//        // check panadapter params
//        XCTAssertEqual(panadapter2.center, center, "Center incorrect")
//        XCTAssertEqual(panadapter2.bandwidth, bandwidth, "Bandwidth incorrect")
//
//        // verify slice added
//        XCTAssertNotEqual(radio!.slices.count, 0, "No Slice")
//
//        // check slice params
//        XCTAssertEqual(radio!.slices[0]!.frequency, sliceFrequency, "Slice frequency incorrect")
//      }
//    }
//    // remove any panadapters & slices
//    removeAllPanadapters(radio: radio!)
//
//    // disconnect the radio
//    Api.sharedInstance.disconnect()
//  }

  // MARK: ---- Tnf ----
   
  private var tnfStatus = "1 freq=14.26 depth=2 width=0.000100 permanent=1"
  func testTnfParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: ObjectId = tnfStatus.keyValuesArray()[0].key.objectId!
    Tnf.parseStatus(radio!, tnfStatus.keyValuesArray(), true)

    let tnf = radio!.tnfs[id]
    XCTAssertNotNil(tnf, "Failed to create Tnf")
    XCTAssertEqual(tnf?.depth, 2)
    XCTAssertEqual(tnf?.frequency, 14_260_000)
    XCTAssertEqual(tnf?.permanent, true)
    XCTAssertEqual(tnf?.width, 100)
    
    tnf?.remove()
    XCTAssertEqual(radio!.tnfs[id], nil, "Failed to remove Tnf")
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // MARK: ---- Waterfall ----
     
  private var waterfallStatus = "waterfall 0x42000000 x_pixels=50 center=14.100000 bandwidth=0.200000 band_zoom=0 segment_zoom=0 line_duration=100 rfgain=0 rxant=ANT1 wide=0 loopa=0 loopb=0 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 panadapter=40000000 color_gain=50 auto_black=1 black_level=20 gradient_index=1 xvtr="
  func testWaterfallParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: StreamId = waterfallStatus.keyValuesArray()[1].key.streamId!
    Waterfall.parseStatus(radio!, waterfallStatus.keyValuesArray(), true)
    let waterfall = radio!.waterfalls[id]

    XCTAssertNotNil(waterfall, "Failed to create Waterfall")
    XCTAssertEqual(waterfall?.autoBlackEnabled, true)
    XCTAssertEqual(waterfall?.blackLevel, 20)
    XCTAssertEqual(waterfall?.colorGain, 50)
    XCTAssertEqual(waterfall?.gradientIndex, 1)
    XCTAssertEqual(waterfall?.lineDuration, 100)
    XCTAssertEqual(waterfall?.panadapterId, "0x40000000".streamId)
    
//    waterfall?.remove()
//    XCTAssertEqual(radio!.waterfalls[id], nil, "Failed to remove Waterfall")
    
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  // MARK: ---- Xvtr ----
   
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
    
    let id: XvtrId = status.keyValuesArray()[0].key
    Xvtr.parseStatus(radio!, status.keyValuesArray(), true)
    let xvtr = radio!.xvtrs[id]
    
    XCTAssertNotNil(xvtr, "Failed to create Xvtr")
    XCTAssertEqual(xvtr?.ifFrequency, 28_000_000)
    XCTAssertEqual(xvtr?.isValid, true)
    XCTAssertEqual(xvtr?.loError, 0)
    XCTAssertEqual(xvtr?.name, expectedName)
    XCTAssertEqual(xvtr?.maxPower, 10)
    XCTAssertEqual(xvtr?.order, 0)
    XCTAssertEqual(xvtr?.preferred, true)
    XCTAssertEqual(xvtr?.rfFrequency, 220_000_000)
    XCTAssertEqual(xvtr?.rxGain, 0)
    XCTAssertEqual(xvtr?.rxOnly, true)
    XCTAssertEqual(xvtr?.twoMeterInt, 0)
    
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
