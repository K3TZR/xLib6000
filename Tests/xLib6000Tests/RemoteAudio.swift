//
//  File.swift
//  
//
//  Created by Douglas Adams on 2/11/20.
//
import XCTest
@testable import xLib6000

final class RemoteAudioTests: XCTestCase {
  
  // Helper functions
  func discoverRadio(logState: Api.NSLogState = (false, "")) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("\n***** Radio found")
      
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "RemoteAudioTests", logState: logState) {
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
}
