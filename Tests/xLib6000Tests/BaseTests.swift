//
//  File.swift
//  
//
//  Created by Douglas Adams on 2/10/20.
//
import XCTest
@testable import xLib6000

final class BaseTests: XCTestCase {
  let showInfoMessages = false

  // ------------------------------------------------------------------------------
  // MARK: - Api
  
  func testApi() {
    
    Swift.print("\n***** \(#function)")
    
    let api = Api.sharedInstance
    XCTAssertNotNil(api, "\n***** Api singleton not present *****\n")
    XCTAssertNotNil(api.tcp, "\n***** Failed to instantiate TcpManager *****\n")
    XCTAssertNotNil(api.udp, "\n***** Failed to instantiate UdpManager *****\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Log
  
  func testLog() {
    
    Swift.print("\n***** \(#function)")
    
    let log = Log.sharedInstance
    XCTAssertNotNil(log, "\n***** Log singleton not present *****\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Discovery
  
  func testDiscovery() {
    
    Swift.print("\n***** \(#function)")
    
    let discovery = Discovery.sharedInstance
    sleep(2)
    XCTAssertGreaterThan(discovery.discoveredRadios.count, 0, "\n***** No Radios discovered *****\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Objects
  
  func testObjectCreation() {
    
    Swift.print("\n***** \(#function)")
    
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "\n***** Failed to instantiate Radio *****\n")
    
    XCTAssertNotNil(radio.atu, "\n***** Failed to instantiate Atu *****\n")
    XCTAssertNotNil(radio.cwx, "\n***** Failed to instantiate Cwx *****\n")
    XCTAssertNotNil(radio.gps, "\n***** Failed to instantiate Gps *****\n")
    XCTAssertNotNil(radio.interlock, "\n***** Failed to instantiate Interlock *****\n")
    XCTAssertNotNil(radio.transmit, "\n***** Failed to instantiate Transmit *****\n")
    XCTAssertNotNil(radio.wan, "\n***** Failed to instantiate Wan *****\n")
    XCTAssertNotNil(radio.waveform, "\n***** Failed to instantiate Waveform *****\n")
    
    let amplifier = Amplifier(radio: radio, id: "0x1234abcd".streamId!)
    XCTAssertNotNil(amplifier, "\n***** Failed to instantiate Amplifier *****\n")
    
    let audioStream = AudioStream(radio: radio, id: "0x41000000".streamId!)
    XCTAssertNotNil(audioStream, "\n***** Failed to instantiate AudioStream *****\n")
    
    let daxIqStream = DaxIqStream(radio: radio, id: 1)
    XCTAssertNotNil(daxIqStream, "\n***** Failed to instantiate DaxIqStream *****\n")
    
    let daxMicAudioStream = DaxMicAudioStream(radio: radio, id: "0x42000000".streamId!)
    XCTAssertNotNil(daxMicAudioStream, "\n***** Failed to instantiate DaxMicAudioStream *****\n")
    
    let daxRxAudioStream = DaxRxAudioStream(radio: radio, id: "0x43000000".streamId!)
    XCTAssertNotNil(daxRxAudioStream, "\n***** Failed to instantiate DaxRxAudioStream *****\n")
    
    let daxTxAudioStream = DaxTxAudioStream(radio: radio, id: "0x44000000".streamId!)
    XCTAssertNotNil(daxTxAudioStream, "\n***** Failed to instantiate DaxTxAudioStream *****\n")
    
    let rxEqualizer = Equalizer(radio: radio, id: "rxsc")
    XCTAssertNotNil(rxEqualizer, "\n***** Failed to instantiate Rx Equalizer *****\n")
    
    let txEqualizer = Equalizer(radio: radio, id: "txsc")
    XCTAssertNotNil(txEqualizer, "\n***** Failed to instantiate Tx Equalizer *****\n")
    
    let iqStream = IqStream(radio: radio, id: 1)
    XCTAssertNotNil(iqStream, "\n***** Failed to instantiate IqStream *****\n")
    
    let memory = Memory(radio: radio, id: "0".objectId!)
    XCTAssertNotNil(memory, "\n***** Failed to instantiate Memory *****\n")
    
    let meter = Meter(radio: radio, id: 1)
    XCTAssertNotNil(meter, "\n***** Failed to instantiate Meter *****\n")
    
    let micAudioStream = MicAudioStream(radio: radio, id: "0x45000000".streamId!)
    XCTAssertNotNil(micAudioStream, "\n***** Failed to instantiate MicAudioStream *****\n")
    
    let opus = Opus(radio: radio, id: "0x46000000".streamId!)
    XCTAssertNotNil(opus, "\n***** Failed to instantiate Opus *****\n")
    
    let pan = Panadapter(radio: radio, id: "0x40000000".streamId!)
    XCTAssertNotNil(pan, "\n***** Failed to instantiate Panadapter *****\n")
    
    let globalProfile = Profile(radio: radio, id: "global")
    XCTAssertNotNil(globalProfile, "\n***** Failed to instantiate Global Profile *****\n")
    
    let micProfile = Profile(radio: radio, id: "mic")
    XCTAssertNotNil(micProfile, "\n***** Failed to instantiate Mic Profile *****\n")
    
    let txProfile = Profile(radio: radio, id: "tx")
    XCTAssertNotNil(txProfile, "\n***** Failed to instantiate Tx Profile *****\n")
    
    let remoteRxAudioStream = RemoteRxAudioStream(radio: radio, id: "0x47000000".streamId!)
    XCTAssertNotNil(remoteRxAudioStream, "\n***** Failed to instantiate RemoteRxAudioStream *****\n")
    
    let remoteTxAudioStream = RemoteTxAudioStream(radio: radio, id: "0x48000000".streamId!)
    XCTAssertNotNil(remoteTxAudioStream, "\n***** Failed to instantiate RemoteTxAudioStream *****\n")
    
    let slice = Slice(radio: radio, id: "1".objectId!)
    XCTAssertNotNil(slice, "\n***** Failed to instantiate Slice *****\n")
    
    let tnf = Tnf(radio: radio, id: 1)
    XCTAssertNotNil(tnf, "\n***** Failed to instantiate Tnf *****\n")
    
    let txAudioStream = TxAudioStream(radio: radio, id: "0x49000000".streamId!)
    XCTAssertNotNil(txAudioStream, "\n***** Failed to instantiate TxAudioStream *****\n")
    
    let usbCableBcd = UsbCable(radio: radio, id: "abcd", cableType: .bcd)
    XCTAssertNotNil(usbCableBcd, "\n***** Failed to instantiate BCD UsbCable *****\n")
    
    let usbCableBit = UsbCable(radio: radio, id: "defg", cableType: .bit)
    XCTAssertNotNil(usbCableBit, "\n***** Failed to instantiate BIT UsbCable *****\n")
    
    let usbCableCat = UsbCable(radio: radio, id: "hijk", cableType: .cat)
    XCTAssertNotNil(usbCableCat, "\n***** Failed to instantiate CAT UsbCable *****\n")
    
    let usbCableDstar = UsbCable(radio: radio, id: "lmno", cableType: .dstar)
    XCTAssertNotNil(usbCableDstar, "\n***** Failed to instantiate DSTAR UsbCable *****\n")
    
    let usbCableLdpa = UsbCable(radio: radio, id: "pqrs", cableType: .ldpa)
    XCTAssertNotNil(usbCableLdpa, "\n***** Failed to instantiate LDPA UsbCable *****\n")
    
    let waterfall = Waterfall(radio: radio, id: "0x40000001".streamId!)
    XCTAssertNotNil(waterfall, "\n***** Failed to instantiate Waterfall *****\n")
    
    let xvtr = Xvtr(radio: radio, id: "1".objectId!)
    XCTAssertNotNil(xvtr, "\n***** Failed to instantiate Xvtr *****\n")
  }
}
