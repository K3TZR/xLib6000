//
//  Frames.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/20/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation
import AVFoundation

/// Struct containing Audio Stream data
///
///   populated by the Audio Stream vitaHandler
///
public struct AudioStreamFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var daxChannel                     = -1
  public private(set) var samples           = 0                             // number of samples (L/R) in this frame
  public var leftAudio                      = [Float]()                     // Array of left audio samples
  public var rightAudio                     = [Float]()                     // Array of right audio samples
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an AudioStreamFrame
  ///
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfBytes:  number of bytes in the payload
  ///
  public init(payload: UnsafeRawBufferPointer, numberOfBytes: Int) {
    
    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfBytes / (4 * 2)
    
    // allocate the samples arrays
    self.leftAudio = [Float](repeating: 0, count: samples)
    self.rightAudio = [Float](repeating: 0, count: samples)
  }
  /// Initialize an AudioStreamFrame
  ///
  /// - Parameters:
  ///   - payload:          pointer to a Vita packet payload
  ///   - numberOfSamples:  number of samples (L/R) needed
  ///
  public init(payload: UnsafeRawBufferPointer, numberOfSamples: Int) {
    
    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfSamples
    
    // allocate the samples arrays
    self.leftAudio = [Float](repeating: 0, count: samples)
    self.rightAudio = [Float](repeating: 0, count: samples)
  }
}

/// Struct containing IQ Stream data
///
///   populated by the IQ Stream vitaHandler
///
public struct IqStreamFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var daxIqChannel                   = -1
  public private(set) var samples           = 0                             // number of samples (L/R) in this frame
  public var realSamples                    = [Float]()                     // Array of real (I) samples
  public var imagSamples                    = [Float]()                     // Array of imag (Q) samples
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an IqStreamFrame
  ///
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfBytes:  number of bytes in the payload
  ///
  public init(payload: UnsafeRawBufferPointer, numberOfBytes: Int) {
    
    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfBytes / (4 * 2)
    
    // allocate the samples arrays
    self.realSamples = [Float](repeating: 0, count: samples)
    self.imagSamples = [Float](repeating: 0, count: samples)
  }
}

/// Struct containing Mic Audio Stream data
///
public struct MicAudioStreamFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var samples           = 0                             // number of samples (L/R) in this frame
  public var leftAudio                      = [Float]()                     // Array of left audio samples
  public var rightAudio                     = [Float]()                     // Array of right audio samples
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a MicAudioStreamFrame
  ///
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfWords:  number of 32-bit Words in the payload
  ///
  public init(payload: UnsafeRawBufferPointer, numberOfBytes: Int) {

    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfBytes / (4 * 2)

    // allocate the samples arrays
    self.leftAudio = [Float](repeating: 0, count: samples)
    self.rightAudio = [Float](repeating: 0, count: samples)
  }
  /// Initialize an MicAudioStreamFrame
  ///
  /// - Parameters:
  ///   - payload:          pointer to a Vita packet payload
  ///   - numberOfSamples:  number of samples (L/R) needed
  ///
  public init(payload: UnsafeRawBufferPointer, numberOfSamples: Int) {

    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfSamples

    // allocate the samples arrays
    self.leftAudio = [Float](repeating: 0, count: samples)
    self.rightAudio = [Float](repeating: 0, count: samples)
  }
}

/// Struct containing Opus Stream data
///
public struct OpusFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var samples: [UInt8]                     // array of samples
  public var numberOfSamples: Int                 // number of samples
//  public var duration: Float                     // frame duration (ms)
//  public var channels: Int                       // number of channels (1 or 2)
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an OpusFrame
  ///
  /// - Parameters:
  ///   - payload:            pointer to the Vita packet payload
  ///   - numberOfSamples:    number of Samples in the payload
  ///
  public init(payload: [UInt8], sampleCount: Int) {
    
    // allocate the samples array
    samples = [UInt8](repeating: 0, count: sampleCount)
    
    // save the count and copy the data
    numberOfSamples = sampleCount
    memcpy(&samples, payload, sampleCount)
    
    // Flex 6000 series uses:
    //     duration = 10 ms
    //     channels = 2 (stereo)
    
//    // determine the frame duration
//    let durationCode = (samples[0] & 0xF8)
//    switch durationCode {
//    case 0xC0:
//      duration = 2.5
//    case 0xC8:
//      duration = 5.0
//    case 0xD0:
//      duration = 10.0
//    case 0xD8:
//      duration = 20.0
//    default:
//      duration = 0
//    }
//    // determine the number of channels (mono = 1, stereo = 2)
//    channels = (samples[0] & 0x04) == 0x04 ? 2 : 1
  }
}

