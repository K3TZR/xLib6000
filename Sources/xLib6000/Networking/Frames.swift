//
//  Frames.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/20/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation
import AVFoundation

/// Class containing Panadapter Stream data
///
///   populated by the Panadapter vitaHandler
///
public class PanadapterFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var startingBin       = 0                             // Index of first bin
  public private(set) var numberOfBins      = 0                             // Number of bins
  public private(set) var binSize           = 0                             // Bin size in bytes
  public private(set) var totalBins         = 0                             // number of bins in the complete frame
  public private(set) var receivedFrame     = 0                             // Frame number
  public var bins                           = [UInt16]()                    // Array of bin values
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _log                          = Log.sharedInstance.msg
  
  private struct PayloadHeaderOld {                                        // struct to mimic payload layout
    var startingBin                         : UInt32
    var numberOfBins                        : UInt32
    var binSize                             : UInt32
    var frameIndex                          : UInt32
  }
  private struct PayloadHeader {                                            // struct to mimic payload layout
    var startingBin                         : UInt16
    var numberOfBins                        : UInt16
    var binSize                             : UInt16
    var totalBins                           : UInt16
    var frameIndex                          : UInt32
  }
  private var _expectedIndex                = 0
  //  private var _binsProcessed                = 0
  private var _byteOffsetToBins             = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a PanadapterFrame
  ///
  /// - Parameter frameSize:    max number of Panadapter samples
  ///
  public init(frameSize: Int) {
    
    // allocate the bins array
    self.bins = [UInt16](repeating: 0, count: frameSize)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Accumulate Vita object(s) into a PanadapterFrame
  ///
  /// - Parameter vita:         incoming Vita object
  /// - Returns:                true if entire frame processed
  ///
  public func accumulate(vita: Vita, expectedFrame: inout Int) -> Bool {
    
    let payloadPtr = UnsafeRawPointer(vita.payloadData)
    
    if Api.sharedInstance.radioVersion.major == 2 && Api.sharedInstance.radioVersion.minor >= 3 {
      // 2.3.x or greater
      // Bins are just beyond the payload
      _byteOffsetToBins = MemoryLayout<PayloadHeader>.size
      
      // map the payload to the New Payload struct
      let p = payloadPtr.bindMemory(to: PayloadHeader.self, capacity: 1)
      
      // byte swap and convert each payload component
      startingBin = Int(CFSwapInt16BigToHost(p.pointee.startingBin))
      numberOfBins = Int(CFSwapInt16BigToHost(p.pointee.numberOfBins))
      binSize = Int(CFSwapInt16BigToHost(p.pointee.binSize))
      totalBins = Int(CFSwapInt16BigToHost(p.pointee.totalBins))
      receivedFrame = Int(CFSwapInt32BigToHost(p.pointee.frameIndex))
      
    } else {
      // pre 2.3.x
      // Bins are just beyond the payload
      _byteOffsetToBins = MemoryLayout<PayloadHeaderOld>.size
      
      // map the payload to the Old Payload struct
      let p = payloadPtr.bindMemory(to: PayloadHeaderOld.self, capacity: 1)
      
      // byte swap and convert each payload component
      startingBin = Int(CFSwapInt32BigToHost(p.pointee.startingBin))
      numberOfBins = Int(CFSwapInt32BigToHost(p.pointee.numberOfBins))
      binSize = Int(CFSwapInt32BigToHost(p.pointee.binSize))
      totalBins = numberOfBins
      receivedFrame = Int(CFSwapInt32BigToHost(p.pointee.frameIndex))
    }
    // initial frame?
    if expectedFrame == -1 { expectedFrame = receivedFrame }
    
    switch (expectedFrame, receivedFrame) {
      
    case (let expected, let received) where received < expected:
      // from a previous group, ignore it
      _log("Ignored frame(s): expected = \(expected), received = \(received)", .warning, #function, #file, #line)
      return false
      
    case (let expected, let received) where received > expected:
      // from a later group, jump forward
      _log("Missing frame(s): expected = \(expected), received = \(received)", .warning, #function, #file, #line)
      expectedFrame = received
      fallthrough
      
    default:
      // received == expected
      // get a pointer to the Bins in the payload
      let binsPtr = payloadPtr.advanced(by: _byteOffsetToBins).bindMemory(to: UInt16.self, capacity: numberOfBins)
      
      // Swap the byte ordering of the data & place it in the bins
      for i in 0..<numberOfBins {
        bins[i+startingBin] = CFSwapInt16BigToHost( binsPtr.advanced(by: i).pointee )
      }
      
      // reset the count if the entire frame has been accumulated
      if startingBin + numberOfBins == totalBins { numberOfBins = totalBins  ; expectedFrame += 1 }
    }
    // return true if the entire frame has been accumulated
    return numberOfBins == totalBins
  }
}

/// Class containing Waterfall Stream data
///
///   populated by the Waterfall vitaHandler
///
public class WaterfallFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var firstBinFreq      : CGFloat   = 0.0               // Frequency of first Bin (Hz)
  public private(set) var binBandwidth      : CGFloat   = 0.0               // Bandwidth of a single bin (Hz)
  public private(set) var lineDuration      = 0                             // Duration of this line (ms)
  public private(set) var numberOfBins      = 0                             // Number of bins
  public private(set) var height            = 0                             // Height of frame (pixels)
  public private(set) var receivedFrame     = 0                             // Time code
  public private(set) var autoBlackLevel    : UInt32 = 0                    // Auto black level
  public private(set) var totalBins         = 0                             //
  public private(set) var startingBin       = 0                             //
  public var bins                           = [UInt16]()                    // Array of bin values
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _binsProcessed                = 0
  private var _byteOffsetToBins             = 0
  private var _log                          = Log.sharedInstance.msg
  
  private struct PayloadHeaderOld {                                         // struct to mimic payload layout
    var firstBinFreq                        : UInt64                        // 8 bytes
    var binBandwidth                        : UInt64                        // 8 bytes
    var lineDuration                        : UInt32                        // 4 bytes
    var numberOfBins                        : UInt16                        // 2 bytes
    var lineHeight                          : UInt16                        // 2 bytes
    var receivedFrame                       : UInt32                        // 4 bytes
    var autoBlackLevel                      : UInt32                        // 4 bytes
  }
  
  private struct PayloadHeader {                                            // struct to mimic payload layout
    var firstBinFreq                        : UInt64                        // 8 bytes
    var binBandwidth                        : UInt64                        // 8 bytes
    var lineDuration                        : UInt32                        // 4 bytes
    var numberOfBins                        : UInt16                        // 2 bytes
    var height                              : UInt16                        // 2 bytes
    var receivedFrame                       : UInt32                        // 4 bytes
    var autoBlackLevel                      : UInt32                        // 4 bytes
    var totalBins                           : UInt16                        // 2 bytes
    var firstBin                            : UInt16                        // 2 bytes
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a WaterfallFrame
  ///
  /// - Parameter frameSize:    max number of Waterfall samples
  ///
  public init(frameSize: Int) {
    
    // allocate the bins array
    self.bins = [UInt16](repeating: 0, count: frameSize)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Accumulate Vita object(s) into a WaterfallFrame
  ///
  /// - Parameter vita:         incoming Vita object
  /// - Returns:                true if entire frame processed
  ///
  public func accumulate(vita: Vita, expectedFrame: inout Int) -> Bool {
    
    let payloadPtr = UnsafeRawPointer(vita.payloadData)
    
    if Api.sharedInstance.radioVersion.major == 2 && Api.sharedInstance.radioVersion.minor >= 3 {
      // 2.3.x or greater
      // map the payload to the New Payload struct
      let p = payloadPtr.bindMemory(to: PayloadHeader.self, capacity: 1)
      
      // 2.3.x or greater
      // Bins are just beyond the payload
      _byteOffsetToBins = MemoryLayout<PayloadHeader>.size
      
      // byte swap and convert each payload component
      firstBinFreq = CGFloat(CFSwapInt64BigToHost(p.pointee.firstBinFreq)) / 1.048576E6
      binBandwidth = CGFloat(CFSwapInt64BigToHost(p.pointee.binBandwidth)) / 1.048576E6
      lineDuration = Int( CFSwapInt32BigToHost(p.pointee.lineDuration) )
      numberOfBins = Int( CFSwapInt16BigToHost(p.pointee.numberOfBins) )
      height = Int( CFSwapInt16BigToHost(p.pointee.height) )
      receivedFrame = Int( CFSwapInt32BigToHost(p.pointee.receivedFrame) )
      autoBlackLevel = CFSwapInt32BigToHost(p.pointee.autoBlackLevel)
      totalBins = Int( CFSwapInt16BigToHost(p.pointee.totalBins) )
      startingBin = Int( CFSwapInt16BigToHost(p.pointee.firstBin) )
      
    } else {
      // pre 2.3.x
      // map the payload to the Old Payload struct
      let p = payloadPtr.bindMemory(to: PayloadHeaderOld.self, capacity: 1)
      
      // pre 2.3.x
      // Bins are just beyond the payload
      _byteOffsetToBins = MemoryLayout<PayloadHeaderOld>.size
      
      // byte swap and convert each payload component
      firstBinFreq = CGFloat(CFSwapInt64BigToHost(p.pointee.firstBinFreq)) / 1.048576E6
      binBandwidth = CGFloat(CFSwapInt64BigToHost(p.pointee.binBandwidth)) / 1.048576E6
      lineDuration = Int( CFSwapInt32BigToHost(p.pointee.lineDuration) )
      numberOfBins = Int( CFSwapInt16BigToHost(p.pointee.numberOfBins) )
      height = Int( CFSwapInt16BigToHost(p.pointee.lineHeight) )
      receivedFrame = Int( CFSwapInt32BigToHost(p.pointee.receivedFrame) )
      autoBlackLevel = CFSwapInt32BigToHost(p.pointee.autoBlackLevel)
      totalBins = numberOfBins
      startingBin = 0
    }
    // initial frame?
    if expectedFrame == -1 { expectedFrame = receivedFrame }
    
    switch (expectedFrame, receivedFrame) {
      
    case (let expected, let received) where received < expected:
      // from a previous group, ignore it
      _log("Waterfall ignored frame(s): expected = \(expected), received = \(received)", .warning, #function, #file, #line)
      return false
      
    case (let expected, let received) where received > expected:
      // from a later group, jump forward
      _log("Waterfall missing frame(s): expected = \(expected), received = \(received)", .warning, #function, #file, #line)
      expectedFrame = received
      fallthrough
      
    default:
      // received == expected
      // get a pointer to the Bins in the payload
      let binsPtr = payloadPtr.advanced(by: _byteOffsetToBins).bindMemory(to: UInt16.self, capacity: numberOfBins)
      
      // Swap the byte ordering of the data & place it in the bins
      for i in 0..<numberOfBins {
        bins[i+startingBin] = CFSwapInt16BigToHost( binsPtr.advanced(by: i).pointee )
      }

      // reset the count if the entire frame has been accumulated
      if startingBin + numberOfBins == totalBins { numberOfBins = totalBins  ; expectedFrame += 1 }
    }
    // return true if the entire frame has been accumulated
    return numberOfBins == totalBins
  }
}

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
  public init(payload: UnsafeRawPointer, numberOfBytes: Int) {
    
    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfBytes / (4 * 2)
    
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
  
  /// Initialize an IqtreamFrame
  ///
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfBytes:  number of bytes in the payload
  ///
  public init(payload: UnsafeRawPointer, numberOfBytes: Int) {
    
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
  
  /// Initialize a AudioStreamFrame
  ///
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfWords:  number of 32-bit Words in the payload
  ///
  public init(payload: UnsafeRawPointer, numberOfBytes: Int) {
    
    // 4 byte each for left and right sample (4 * 2)
    self.samples = numberOfBytes / (4 * 2)
    
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

