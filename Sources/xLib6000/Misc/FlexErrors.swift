//
//  FlexErrors.swift
//  CommonCode
//
//  Created by Douglas Adams on 12/23/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

/// Given an errorcode return an errorlevel
///
///      Flex 6000 error codes
///      see http://wiki.flexradio.com/index.php?title=Known_API_Responses
///
/// - Parameter errorCode:      error code from reply
/// - Returns:                  error level
///
public func flexErrorLevel(errorCode: String) -> MessageLevel {
  var errorLevel = MessageLevel.info
  
  let number = UInt32(errorCode, radix: 16) ?? 0
  
  switch number {
  case 0x10000001...0x10000003:
    errorLevel = .info
  case 0x31000001...0x31000009:
    errorLevel = .warning
  case 0x50000001...0x500000A3:
    errorLevel = .error
  case 0x50001000...0x50001017:
    errorLevel = .error
  case 0xE2000000:
    errorLevel = .error
  case 0xF3000001...0xF3000004:
    errorLevel = .error
  default:
    errorLevel = .info
  }
  return errorLevel
}

/// Given an errorcode return an explanation
///
/// - Parameter errorCode:      error code from reply
/// - Returns:                  error explanation
///
public func flexErrorString(errorCode: String) -> String {
  var errorString = ""
  
  let number = UInt32(errorCode, radix: 16) ?? 0
  
  switch number {
  case 0:
    errorString = ""
  case 0x10000001...0x10000003:
    errorString = FlexErrors(rawValue: number )!.toString()
  case 0x31000001...0x31000009:
    errorString = FlexErrors(rawValue: number )!.toString()
  case 0x50000001...0x500000A3:
    errorString = FlexErrors(rawValue: number )!.toString()
  case 0x50001000...0x50001017:
    errorString = FlexErrors(rawValue: number )!.toString()
  case 0xE2000000:
    errorString = FlexErrors(rawValue: number )!.toString()
  case 0xF3000001...0xF3000004:
    errorString = FlexErrors(rawValue: number )!.toString()
  default:
    errorString = "Unknown error"
  }
  return errorString
}

/// Enum of all possible Error codes returned by the Radio
///
enum FlexErrors: UInt32 {
  
  // Fatal
  case SLM_F_MAX_CLIENTS                              = 0xF3000001
  case SLM_F_FPGA_TEMP_ERR                            = 0xF3000002
  case SLM_F_REV_POWER_ERR                            = 0xF3000003
  // this is a bogus error displayed on a stolen radio
  case SLM_F_OVERTEMP                                 = 0xF3000004
  
  // Error
  case SL_ERROR                                       = 0xE2000000
  
  // Error Base
  case SL_NO_FOUNDATION_RCVR                          = 0x50000001
  case SL_LICENSE_NO_SLICE_AVAIL                      = 0x50000002
  case SL_ERROR_ALL_SLICES_IN_USE                     = 0x50000003
  case SL_ERROR_SLICE_PARAM                           = 0x50000004
  case SL_MALLOC_FAIL_SIGNAL_CHAIN                    = 0x50000005
  case SL_MALLOC_FAIL_DSP_PROCESS                     = 0x50000006
  case SL_NO_SCU_AVAILABLE                            = 0x50000007
  case SL_SCU_NOT_IN_USE                              = 0x50000008
  case SL_NO_FOUNDATION_RX_AVAILABLE                  = 0x50000009
  case SL_FOUNDATION_RX_NOT_IN_USE                    = 0x5000000a
  case SL_OUT_OF_MEMORY                               = 0x5000000b
  case SL_FREQUENCY_OUT_OF_RANGE                      = 0x5000000c
  case SL_INVALID_SLICE_RECEIVER                      = 0x5000000d
  case SL_INVALID_FOUNDATION_RX                       = 0x5000000e
  case SL_INVALID_DSP_PROCESS                         = 0x5000000f
  
  case SL_INVALID_SIGNAL_CHAIN                        = 0x50000010
  case SL_FREQUENCY_TOO_HIGH                          = 0x50000011
  case SL_NYQUIST_MISMATCH                            = 0x50000012
  case SL_BAD_COMMAND                                 = 0x50000013
  case SL_UNKNOWN_COMMAND                             = 0x50000015
  case SL_MALFORMED_COMMAND                           = 0x50000016
  case SL_NO_SUB                                      = 0x50000017
  case SL_BAD_SCU_NUMBER                              = 0x50000018
  case SL_UNKNOWN_PREAMP                              = 0x50000019
  case SL_NULL_POINTER_IN_SIG_CHAIN                   = 0x5000001A
  case SL_REF_COUNT_UNDERFLOW                         = 0x5000001B
  case SL_INVALID_MINIMIXER_RX                        = 0x5000001C
  case SL_NO_MINIMIXER                                = 0x5000001D
  case SL_SHARED_MINIMIXER                            = 0x5000001E
  case SL_NO_MINIMIXER_IN_RANGE                       = 0x5000001F
  
  case SL_MMX_LIMIT_REACHED                           = 0x50000020
  case SL_SECURITY_FAULT                              = 0x50000021
  case SL_RECAHED_MMX_LIMIT                           = 0x50000022
  case SL_FOUNDATION_MMX_LIMIT                        = 0x50000023
  case SL_AUDIO_CLIENT_NOT_FOUND                      = 0x50000024
  case SL_AUDIO_CLIENT_STREAM_ID_NOT_FOUND            = 0x50000025
  case SL_AUDIO_CLIENT_GAIN_INVALID                   = 0x50000026
  case SL_AUDIO_CLIENT_PAN_INVALID                    = 0x50000027
  case SL_SLICE_RECEIVER_NOT_IN_USE                   = 0x50000028
  case SL_CLIENT_STREAM_ID_NOT_FOUND                  = 0x50000029
  case SL_UNKNOWN_ANT_PORT                            = 0x5000002A
  case SL_INVALID_NUMERIC_VALUE                       = 0x5000002B
  case SL_INCORRECT_NUM_PARAMS                        = 0x5000002C
  case SL_BAD_FIELD                                   = 0x5000002D
  case SL_NO_SUBSCRIPTION                             = 0x5000002E
  case SL_UNIMPLEMENTED_MODE                          = 0x5000002F
  
  case SL_SIGNAL_CHAIN_ERROR                          = 0x50000030
  case SL_RFGAIN_OUT_OF_RANGE                         = 0x50000031
  case SL_BAD_MODE                                    = 0x50000032
  case SL_PARAM_OUT_OF_RANGE                          = 0x50000033
  case SL_BAD_METER                                   = 0x50000034
  case SL_LOW_LEVEL                                   = 0x50000035
  case SL_INVALID_METER                               = 0x50000036
  case SL_TERMINATE                                   = 0x50000037
  case SL_NO_COMMAND                                  = 0x50000038
  case SL_FFT_FPS_OUT_OF_RANGE                        = 0x50000039
  case SL_CLOSE_CLIENT                                = 0x5000003A
  case SL_TXSC_INVALID_TONE_INDEX                     = 0x5000003B
  case SL_INVALID_TX_ANTENNA                          = 0x5000003C
  case SL_TX_NOT_SUPPORTED                            = 0x5000003D
  case SL_BAD_ADC_SOURCE                              = 0x5000003E
  case SL_BAD_CAL_TABLE_TYPE                          = 0x5000003F
  
  case SL_BAD_CAL_TABLE_POINTS                        = 0x50000040
  case SL_CAL_TABLE_READ_FAIL                         = 0x50000041
  case SL_NOT_READY_TO_TRANSMIT                       = 0x50000042
  case SL_NO_TRANSMITTER                              = 0x50000043
  case SL_INVALID_TUNE_POWER                          = 0x50000044
  case SL_UNCALIBRATED_POWER                          = 0x50000045
  case SL_BITE2_FAULT                                 = 0x50000046
  case SL_CALIBRATION_WRITE_FAIL                      = 0x50000047
  case SL_INVALID_RF_POWER                            = 0x50000048
  case SL_READ_EMPTY_CAL_TABLE                        = 0x50000049
  case SL_INVALID_ADL5201_DEVICE                      = 0x5000004A
  case SL_INVALID_MIC_LEVEL                           = 0x5000004B
  case SL_INVALID_ALSA_CONTROL_NAME                   = 0x5000004C
  case SL_INVALID_OSC_INDEX                           = 0x5000004D
  case SL_INVALID_BOOLEAN                             = 0x5000004E
  case SL_INVALID_BIAS_CAL_TARGET                     = 0x5000004F
  
  case SL_INVALID_PA_CLASS                            = 0x50000050
  case SL_MCL_INIT_FAILURE                            = 0x50000051
  case SL_UNEXPECTED_FILE_SIZE                        = 0x50000052
  case SL_FILE_SERVER_BUSY                            = 0x50000053
  case SL_INVALID_TX_EQ_STAGE                         = 0x50000054
  case SL_INVALID_RX_EQ_STAGE                         = 0x50000055
  case SL_INVALID_FILTER                              = 0x50000056
  case SL_STORAGE_NOT_INITIALIZED                     = 0x50000057
  case SL_PTT_TIMEOUT                                 = 0x50000058
  case SL_INVALID_STREAM_ID                           = 0x50000059
  
  case SL_NO_CHANGE_ANT_IN_TX                         = 0x50000060
  case SL_INVALID_DSP_ALG_FOR_MODE                    = 0x50000061
  case SL_INVALID_CLIENT                              = 0x50000062
  case SL_INVALID_FREQUENCY                           = 0x50000063
  case SL_NO_IP_OR_PORT                               = 0x50000064
  case SL_INVALID_DAX_CHANNEL                         = 0x50000065
  //    case SL_NO_DAX_TX                                   = 0x50000066 // seems to be a duplication ???
  case SL_INVALID_DAX_IQ_CHANNEL                      = 0x50000066
  case SL_INVALID_DAX_IQ_RATE                         = 0x50000067
  case SL_SLICE_IS_LOCKED                             = 0x50000068
  case SL_FREQUENCY_TOO_LOW                           = 0x50000069
  case SL_FULL_DUPLEX_NOT_AVAILABLE                   = 0x5000006A
  case SL_DAXIQ_DUPLEX_NOT_AVAILABLE                  = 0x5000006B
  case SL_INVALID_BAND_FOR_PERSISTENCE                = 0x5000006C
  case SL_LOOP_NOT_VALID_FOR_MODEL                    = 0x5000006D
  case SLM_INVALID_CLIENT_NOT_PAN                     = 0x5000006E
  case SL_NO_VALID_CLIENT                             = 0x5000006F
  
  case SL_EXCESS_TX_COMPRESSION_FAIL                  = 0x50000070
  case SL_NO_RECORDED_DATA                            = 0x50000071
  case SL_BAD_ECO_TABLE_TYPE                          = 0x50000072
  case SL_EMPTY_ECO_TABLE                             = 0x50000073
  case SL_FULL_ECO_TABLE                              = 0x50000074
  case SL_BAD_ECO_NUMBER                              = 0x50000075
  case SL_ECO_NOT_FOUND                               = 0x50000076
  case SL_NO_HEADLESS_SLCS                            = 0x50000077
  case SL_INVALID_PROFILE                             = 0x50000078
  case SL_INVALID_CMD_WHILE_XMIT                      = 0x50000079
  case SL_CWX_BAD_MACRO                               = 0x5000007A
  case SL_CWX_BUFFER_OVERFLOW                         = 0x5000007B
  case SL_XVTR_NOT_FOUND                              = 0x5000007C
  case SL_XVTR_CREATE_FAIL                            = 0x5000007D
  case SL_XVTR_DELETED                                = 0x5000007E
  case SL_DIVERSITY_ANT_MISMATCH                      = 0x5000007F
  
  case SL_INVALID_DATABASE_SCHEMA_VERSION             = 0x50000080
  case SL_INVALID_WAVEFORM                            = 0x50000081
  case SL_RESPONSE_WITHOUT_COMMAND                    = 0x50000082
  case SL_UNABLE_TO_SEND_RESPONSE                     = 0x50000083
  case SL_INVALID_MEMORY_INDEX                        = 0x50000084
  case SL_INVALID_CMD_FOR_MODE                        = 0x50000085
  case SL_LOCK_NOT_FOUND                              = 0x50000086
  case SL_KEEPALIVE_FAIL                              = 0x50000087
  case SL_REMOVE_CLIENT                               = 0x50000088
  case SL_CLIENT_CLOSED_SOCKET                        = 0x50000089
  case SL_INVALID_ATU_PROFILE_ID                      = 0x5000008A
  case SL_INVALID_ATU_PROFILE_NAME                    = 0x5000008B
  case SL_ATU_PROFILE_NAME_ALREADY_EXISTS             = 0x5000008C
  case SL_INVALID_EINTERLOCK                          = 0x5000008D
  case SL_COULD_NOT_CREATE_AUDIO_CLIENT               = 0x5000008E
  case SL_NULL_POINTER                                = 0x5000008F
  
  case SL_CWX_INVALID_INDEX                           = 0x50000090
  case SL_CWX_INSERT_FAILED                           = 0x50000091
  case SL_CLIENT_DISCONNECTED_BY_ANOTHER_CLIENT       = 0x50000092
  case SL_BAD_NTP_RATE                                = 0x50000093
  case SL_INVALID_IPV4_IP                             = 0x50000094
  case SL_CLIENT_DISCONNECTED_BY_ABORT                = 0x50000095
  case SL_INVALID_PTT_CMD_IN_CW_MESSAGE               = 0x50000096
  case SL_USB_SERIAL_NUMBER_NOT_FOUND                 = 0x50000097
  case SL_INVALID_CABLE_TYPE                          = 0x50000098
  case SL_INVALID_FREQUENCY_RANGE                     = 0x50000099
  case SL_EXCEEDS_MAX_CHAR_LIMIT                      = 0x5000009A
  case SL_INVALID_SOURCE_TYPE                         = 0x5000009B
  case SL_INVALID_OUTPUT_TYPE                         = 0x5000009C
  case SL_INVALID_BCD_BIT_VALUE                       = 0x5000009D
  case SL_INVALID_BIT_CABLE                           = 0x5000009E
  case SL_USB_CABLE_DELETE_FAILED                     = 0x5000009F
  
  case SL_USB_CABLE_CANT_CHANGE_INVALID_TYPE          = 0x500000A0
  case SL_CWX_UNTERMINATED_INLINE_CMD                 = 0x500000A1
  case SL_CWX_INVALID_INLINE_CMD                      = 0x500000A2
  case SL_INVALID_SUBSCRIPTION                        = 0x500000A3
  
  case SL_RESP_UNKNOWN                                = 0x50001000
  
  case SL_MYSQL_CONNECTION_FAIL                       = 0x50001001
  case SL_MYSQL_LOGIN_FAIL                            = 0x50001002
  case SL_MYSQL_NOT_CONNECTED                         = 0x50001003
  case SL_MYSQL_PCB_ALREADY_REG                       = 0x50001004
  case SL_MYSQL_PCB_NOT_REGISTERED                    = 0x50001005
  case SL_MYSQL_PCB_SN_BLANK                          = 0x50001006
  case SL_MYSQL_PCB_SN_TOO_LONG                       = 0x50001007
  case SL_MYSQL_MNEMONIC_BLANK                        = 0x50001008
  case SL_MYSQL_MNEMONIC_TOO_LONG                     = 0x50001009
  case SL_MYSQL_PCB_REV_BLANK                         = 0x5000100A
  case SL_MYSQL_PCB_REV_TOO_LONG                      = 0x5000100B
  case SL_MYSQL_PCB_MODEL_BLANK                       = 0x5000100C
  case SL_MYSQL_PCB_MODEL_TOO_LONG                    = 0x5000100D
  case SL_MYSQL_BAD_TESTID                            = 0x5000100E
  case SL_MYSQL_PART_DESIG_BLANK                      = 0x5000100F
  
  case SL_MYSQL_SW_NAME_BLANK                         = 0x50001010
  case SL_MYSQL_SW_VERSION_BLANK                      = 0x50001011
  case SL_MYSQL_BOM_REV_BLANK                         = 0x50001012
  case SL_MYSQL_BOM_REV_TOO_LONG                      = 0x50001013
  case SL_MYSQL_BOM_BLANK                             = 0x50001014
  case SL_MYSQL_BOM_TOO_LONG                          = 0x50001015
  case SL_MYSQL_MODEL_BLANK                           = 0x50001016
  case SL_MYSQL_MODEL_TOO_LONG                        = 0x50001017
  
  // Warning
  case SLM_W_SERVICE                                  = 0x31000001
  case SLM_W_NO_TRANSMITTER                           = 0x31000002
  case SLM_W_INTERLOCK                                = 0x31000003
  case SL_W_NOTHING_TO_SEND                           = 0x31000004
  case SLM_W_FPGA_TEMP_WARN                           = 0x31000005
  case SL_W_CWX_NO_MORE                               = 0x31000007
  case SLM_W_DEFAULT_PROFILE                          = 0x31000008
  case SL_W_ATU_MAX_POWER_INTERFERENCE                = 0x31000009
  
  // Info
  case SLM_I_CLIENT_CONNECTED                         = 0x10000001
  case SLM_I_UNKNOWN_CLIENT                           = 0x10000002
  case SL_I_CWX_NOTHING_TO_ERASE                      = 0x10000003
  
  /// Converts an error Enum to a String explanation
  ///
  /// - Returns:                the explanation
  ///
  func toString() -> String {
    
    switch self {
      
    // Fatal
    case .SLM_F_MAX_CLIENTS: return "Maximum number of clients exceeded"                // 0xF3000001
    case .SLM_F_FPGA_TEMP_ERR: return "FPGA temperature"                                // 0xF3000002
    case .SLM_F_REV_POWER_ERR: return "Reverse power"                                   // 0xF3000003
    // this is a bogus error displayed on a stolen radio
    case .SLM_F_OVERTEMP: return "Over temperature"                                     // 0xF3000004
      
    // Error
    case .SL_ERROR: return "Undefined Error"                                            // 0xE2000000
      
    // Error Base
    case .SL_NO_FOUNDATION_RCVR: return "No foundation receiver"                        // 0x50000001
    case .SL_LICENSE_NO_SLICE_AVAIL: return "License, no slice available"               // 0x50000002
    case .SL_ERROR_ALL_SLICES_IN_USE: return "All slices in use"                        // 0x50000003
    case .SL_ERROR_SLICE_PARAM: return "SLice param invalid"                            // 0x50000004
    case .SL_MALLOC_FAIL_SIGNAL_CHAIN: return "Malloc fail signal chain"                // 0x50000005
    case .SL_MALLOC_FAIL_DSP_PROCESS: return "Malloc fail DSP process"                  // 0x50000006
    case .SL_NO_SCU_AVAILABLE: return "No SCU available"                                // 0x50000007
    case .SL_SCU_NOT_IN_USE: return "SCU not in use"                                    // 0x50000008
    case .SL_NO_FOUNDATION_RX_AVAILABLE: return "No foundation receiver available"      // 0x50000009
    case .SL_FOUNDATION_RX_NOT_IN_USE: return "Foundation receiver not in use"          // 0x5000000A
    case .SL_OUT_OF_MEMORY: return "Out of memory"                                      // 0x5000000B
    case .SL_FREQUENCY_OUT_OF_RANGE: return "Frequence out of range"                    // 0x5000000C
    case .SL_INVALID_SLICE_RECEIVER: return "Invalid slice receiver"                    // 0x5000000D
    case .SL_INVALID_FOUNDATION_RX: return "Invalid foundation receiver"                // 0x5000000E
    case .SL_INVALID_DSP_PROCESS: return "Invalid DSP process"                          // 0x5000000F
      
    case .SL_INVALID_SIGNAL_CHAIN: return "Invalid signal chain"                        // 0x50000010
    case .SL_FREQUENCY_TOO_HIGH: return "Frequency too high"                            // 0x50000011
    case .SL_NYQUIST_MISMATCH: return "Nyquist mismatch"                                // 0x50000012
    case .SL_BAD_COMMAND: return "Bad command"                                          // 0x50000013
    case .SL_UNKNOWN_COMMAND: return "Unknown command"                                  // 0x50000015
    case .SL_MALFORMED_COMMAND: return "Malformed command"                              // 0x50000016
    case .SL_NO_SUB: return "No sub"                                                    // 0x50000017
    case .SL_BAD_SCU_NUMBER: return "Bad SCU number"                                    // 0x50000018
    case .SL_UNKNOWN_PREAMP: return "Unknown preamp"                                    // 0x50000019
    case .SL_NULL_POINTER_IN_SIG_CHAIN: return "Null pointer in signal chain"           // 0x5000001A
    case .SL_REF_COUNT_UNDERFLOW: return "Ref counter underflow"                        // 0x5000001B
    case .SL_INVALID_MINIMIXER_RX: return "Invalid minimixer Rx"                        // 0x5000001C
    case .SL_NO_MINIMIXER: return "No minimixer"                                        // 0x5000001D
    case .SL_SHARED_MINIMIXER: return "Shared minimixer"                                // 0x5000001E
    case .SL_NO_MINIMIXER_IN_RANGE: return "No minimixer in range"                      // 0x5000001F
      
    case .SL_MMX_LIMIT_REACHED: return "MMX limit reached"                              // 0x50000020
    case .SL_SECURITY_FAULT: return "Security fault"                                    // 0x50000021
    case .SL_RECAHED_MMX_LIMIT: return "Recahed MMX limit"                              // 0x50000022
    case .SL_FOUNDATION_MMX_LIMIT: return "Foundation MMX limit"                        // 0x50000023
    case .SL_AUDIO_CLIENT_NOT_FOUND: return "Audio client not found"                    // 0x50000024
    case .SL_AUDIO_CLIENT_STREAM_ID_NOT_FOUND: return "Audio client stream id not found"// 0x50000025
    case .SL_AUDIO_CLIENT_GAIN_INVALID: return "Audio client gain invalid"              // 0x50000026
    case .SL_AUDIO_CLIENT_PAN_INVALID: return "Audio client pan invalid"                // 0x50000027
    case .SL_SLICE_RECEIVER_NOT_IN_USE: return "Slice receiver not in use"              // 0x50000028
    case .SL_CLIENT_STREAM_ID_NOT_FOUND: return "Client stream id not found"            // 0x50000029
    case .SL_UNKNOWN_ANT_PORT: return "Unknown ant port"                                // 0x5000002A
    case .SL_INVALID_NUMERIC_VALUE: return "Invalid numeric value"                      // 0x5000002B
    case .SL_INCORRECT_NUM_PARAMS: return "Incorrect number of params"                  // 0x5000002C
    case .SL_BAD_FIELD: return "Bad field"                                              // 0x5000002D
    case .SL_NO_SUBSCRIPTION: return "No sunscription"                                  // 0x5000002E
    case .SL_UNIMPLEMENTED_MODE: return "Unimplemented mode"                            // 0x5000002F
      
    case .SL_SIGNAL_CHAIN_ERROR: return "Signal chain error"                            // 0x50000030
    case .SL_RFGAIN_OUT_OF_RANGE: return "RF gain out of range"                         // 0x50000031
    case .SL_BAD_MODE: return "Bad mode"                                                // 0x50000032
    case .SL_PARAM_OUT_OF_RANGE: return "Param out of range"                            // 0x50000033
    case .SL_BAD_METER: return "Bad meter"                                              // 0x50000034
    case .SL_LOW_LEVEL: return "Low level"                                              // 0x50000035
    case .SL_INVALID_METER: return "Invalid meter"                                      // 0x50000036
    case .SL_TERMINATE: return "Terminate"                                              // 0x50000037
    case .SL_NO_COMMAND: return "No command"                                            // 0x50000038
    case .SL_FFT_FPS_OUT_OF_RANGE: return "FFT FPS out of range"                        // 0x50000039
    case .SL_CLOSE_CLIENT: return "Close client"                                        // 0x5000003A
    case .SL_TXSC_INVALID_TONE_INDEX: return "TXSC invalid tone index"                  // 0x5000003B
    case .SL_INVALID_TX_ANTENNA: return "Invalid TX antenna"                            // 0x5000003C
    case .SL_TX_NOT_SUPPORTED: return "TX not supported"                                // 0x5000003D
    case .SL_BAD_ADC_SOURCE: return "Bad ADC source"                                    // 0x5000003E
    case .SL_BAD_CAL_TABLE_TYPE: return "Bad cal table type"                            // 0x5000003F
      
    case .SL_BAD_CAL_TABLE_POINTS: return "Bad cal table points"                        // 0x50000040
    case .SL_CAL_TABLE_READ_FAIL: return "Cal table read fail"                          // 0x50000041
    case .SL_NOT_READY_TO_TRANSMIT: return "Not ready to transmit"                      // 0x50000042
    case .SL_NO_TRANSMITTER: return "No transmitter"                                    // 0x50000043
    case .SL_INVALID_TUNE_POWER: return "Invalid tune power"                            // 0x50000044
    case .SL_UNCALIBRATED_POWER: return "Uncalibrated power"                            // 0x50000045
    case .SL_BITE2_FAULT: return "Bite2 fault"                                          // 0x50000046
    case .SL_CALIBRATION_WRITE_FAIL: return "Calibration write fail"                    // 0x50000047
    case .SL_INVALID_RF_POWER: return "Invalid RF power"                                // 0x50000048
    case .SL_READ_EMPTY_CAL_TABLE: return "Read empty cal table"                        // 0x50000049
    case .SL_INVALID_ADL5201_DEVICE: return "Invalid ADL5201 device"                    // 0x5000004A
    case .SL_INVALID_MIC_LEVEL: return "Invalid mic level"                              // 0x5000004B
    case .SL_INVALID_ALSA_CONTROL_NAME: return "Invalid ALSA control name"              // 0x5000004C
    case .SL_INVALID_OSC_INDEX: return "Invalid OSC index"                              // 0x5000004D
    case .SL_INVALID_BOOLEAN: return "Invalid boolean"                                  // 0x5000004E
    case .SL_INVALID_BIAS_CAL_TARGET: return "Invalid bias cal target"                  // 0x5000004F
      
    case .SL_INVALID_PA_CLASS: return "Invalid PA class"                                // 0x50000050
    case .SL_MCL_INIT_FAILURE: return "MLC init failure"                                // 0x50000051
    case .SL_UNEXPECTED_FILE_SIZE: return "Unexpected file size"                        // 0x50000052
    case .SL_FILE_SERVER_BUSY: return "File server busy"                                // 0x50000053
    case .SL_INVALID_TX_EQ_STAGE: return "Invalid TX EQ stage"                          // 0x50000054
    case .SL_INVALID_RX_EQ_STAGE: return "Invalid RX EQ stage"                          // 0x50000055
    case .SL_INVALID_FILTER: return "Invalid filter"                                    // 0x50000056
    case .SL_STORAGE_NOT_INITIALIZED: return "Storage not initialized"                  // 0x50000057
    case .SL_PTT_TIMEOUT: return "PTT timeout"                                          // 0x50000058
    case .SL_INVALID_STREAM_ID: return "Invalid stream id"                              // 0x50000059
      
    case .SL_NO_CHANGE_ANT_IN_TX: return "No change ant in TX"                          // 0x50000060
    case .SL_INVALID_DSP_ALG_FOR_MODE: return "Invalid DSP alg for mode"                // 0x50000061
    case .SL_INVALID_CLIENT: return "Invalid client"                                    // 0x50000062
    case .SL_INVALID_FREQUENCY: return "Invalid frrequency"                             // 0x50000063
    case .SL_NO_IP_OR_PORT: return "No Ip adddress or Port number"                      // 0x50000064
    case .SL_INVALID_DAX_CHANNEL: return "Invalid DAX channel"                          // 0x50000065
    //    case .SL_NO_DAX_TX: return "" //                           = 0x50000066 // seems to be a duplication ???
    case .SL_INVALID_DAX_IQ_CHANNEL: return "Invalid DAX IQ channel"                    // 0x50000066
    case .SL_INVALID_DAX_IQ_RATE: return "Invalid DAX IQ rate"                          // 0x50000067
    case .SL_SLICE_IS_LOCKED: return "Slice is locked"                                  // 0x50000068
    case .SL_FREQUENCY_TOO_LOW: return "Frequency too low"                              // 0x50000069
    case .SL_FULL_DUPLEX_NOT_AVAILABLE: return "Full duplex not available"              // 0x5000006A
    case .SL_DAXIQ_DUPLEX_NOT_AVAILABLE: return ""                                      // 0x5000006B
    case .SL_INVALID_BAND_FOR_PERSISTENCE: return "Invalid band for persistence"        // 0x5000006C
    case .SL_LOOP_NOT_VALID_FOR_MODEL: return "Loop not valid for model"                // 0x5000006D
    case .SLM_INVALID_CLIENT_NOT_PAN: return "Invalid client not pan"                   // 0x5000006E
    case .SL_NO_VALID_CLIENT: return "No valid client"                                  // 0x5000006F
      
    case .SL_EXCESS_TX_COMPRESSION_FAIL: return "Excess TX compression fail"            // 0x50000070
    case .SL_NO_RECORDED_DATA: return "No recorder data"                                // 0x50000071
    case .SL_BAD_ECO_TABLE_TYPE: return "Bad ECO table type"                            // 0x50000072
    case .SL_EMPTY_ECO_TABLE: return "Empty ECO table"                                  // 0x50000073
    case .SL_FULL_ECO_TABLE: return "Full ECO table"                                    // 0x50000074
    case .SL_BAD_ECO_NUMBER: return "Bad ECO number"                                    // 0x50000075
    case .SL_ECO_NOT_FOUND: return "ECO not found"                                      // 0x50000076
    case .SL_NO_HEADLESS_SLCS: return "No headless SLCS"                                // 0x50000077
    case .SL_INVALID_PROFILE: return "Invalid profile"                                  // 0x50000078
    case .SL_INVALID_CMD_WHILE_XMIT: return "Invalid cmd while TX"                      // 0x50000079
    case .SL_CWX_BAD_MACRO: return "CWX bad macro"                                      // 0x5000007A
    case .SL_CWX_BUFFER_OVERFLOW: return "CWX buffer overflow"                          // 0x5000007B
    case .SL_XVTR_NOT_FOUND: return "XVTR not found"                                    // 0x5000007C
    case .SL_XVTR_CREATE_FAIL: return "XVTR create fail"                                // 0x5000007D
    case .SL_XVTR_DELETED: return "XVTR deleted"                                        // 0x5000007E
    case .SL_DIVERSITY_ANT_MISMATCH: return "Diversity ant mismatch"                    // 0x5000007F
      
    case .SL_INVALID_DATABASE_SCHEMA_VERSION: return "Invalid database schema version"  // 0x50000080
    case .SL_INVALID_WAVEFORM: return "Invalid waveform"                                // 0x50000081
    case .SL_RESPONSE_WITHOUT_COMMAND: return "Response without command"                // 0x50000082
    case .SL_UNABLE_TO_SEND_RESPONSE: return "Unable to send response"                  // 0x50000083
    case .SL_INVALID_MEMORY_INDEX: return "Invalid memory index"                        // 0x50000084
    case .SL_INVALID_CMD_FOR_MODE: return "Invalid cmd for mode"                        // 0x50000085
    case .SL_LOCK_NOT_FOUND: return "Lock not found"                                    // 0x50000086
    case .SL_KEEPALIVE_FAIL: return "Keepalive fail"                                    // 0x50000087
    case .SL_REMOVE_CLIENT: return "Remove client"                                      // 0x50000088
    case .SL_CLIENT_CLOSED_SOCKET: return "Client closed socket"                        // 0x50000089
    case .SL_INVALID_ATU_PROFILE_ID: return "Invalid ATU profile id"                    // 0x5000008A
    case .SL_INVALID_ATU_PROFILE_NAME: return "Invalid ATU profile name"                // 0x5000008B
    case .SL_ATU_PROFILE_NAME_ALREADY_EXISTS: return "ATU profile name already exists"  // 0x5000008C
    case .SL_INVALID_EINTERLOCK: return "Invalid einterlock"                            // 0x5000008D
    case .SL_COULD_NOT_CREATE_AUDIO_CLIENT: return "Could not create audio client"      // 0x5000008E
    case .SL_NULL_POINTER: return "Null pointer"                                        // 0x5000008F
      
    case .SL_CWX_INVALID_INDEX: return "CWX invalid endex"                              // 0x50000090
    case .SL_CWX_INSERT_FAILED: return "CWX insert failed"                              // 0x50000091
    case .SL_CLIENT_DISCONNECTED_BY_ANOTHER_CLIENT: return "Client disconnected by another client" // = 0x50000092
    case .SL_BAD_NTP_RATE: return "Bad NTP rate"                                        // 0x50000093
    case .SL_INVALID_IPV4_IP: return "Invalid IPV4 ip address"                          // 0x50000094
    case .SL_CLIENT_DISCONNECTED_BY_ABORT: return "Client disconnected by abort"        // 0x50000095
    case .SL_INVALID_PTT_CMD_IN_CW_MESSAGE: return "Invalid PTT cmd in CW message"      // 0x50000096
    case .SL_USB_SERIAL_NUMBER_NOT_FOUND: return "USB serial number not found"          // 0x50000097
    case .SL_INVALID_CABLE_TYPE: return "Invalid cable type"                            // 0x50000098
    case .SL_INVALID_FREQUENCY_RANGE: return "Invalid frequency range"                  // 0x50000099
    case .SL_EXCEEDS_MAX_CHAR_LIMIT: return "Exceeds max char limit"                    // 0x5000009A
    case .SL_INVALID_SOURCE_TYPE: return "Invalid source type"                          // 0x5000009B
    case .SL_INVALID_OUTPUT_TYPE: return "Invalid output type"                          // 0x5000009C
    case .SL_INVALID_BCD_BIT_VALUE: return "Invalid BCD bit value"                      // 0x5000009D
    case .SL_INVALID_BIT_CABLE: return "Invalid BIT cable"                              // 0x5000009E
    case .SL_USB_CABLE_DELETE_FAILED: return "USB cable delete failed"                  // 0x5000009F
      
    case .SL_USB_CABLE_CANT_CHANGE_INVALID_TYPE: return ""                              // 0x500000A0
    case .SL_CWX_UNTERMINATED_INLINE_CMD: return ""                                     // 0x500000A1
    case .SL_CWX_INVALID_INLINE_CMD: return ""                                          // 0x500000A2
    case .SL_INVALID_SUBSCRIPTION: return ""                                            // 0x500000A3
      
    case .SL_RESP_UNKNOWN: return "Response unknown"                                    // 0x50001000
      
    case .SL_MYSQL_CONNECTION_FAIL: return "SQL connection fail"                        // 0x50001001
    case .SL_MYSQL_LOGIN_FAIL: return "SQL login fail"                                  // 0x50001002
    case .SL_MYSQL_NOT_CONNECTED: return "SQL not connected"                            // 0x50001003
    case .SL_MYSQL_PCB_ALREADY_REG: return "SQL pcb already registered"                 // 0x50001004
    case .SL_MYSQL_PCB_NOT_REGISTERED: return "SQL pcb not registered"                  // 0x50001005
    case .SL_MYSQL_PCB_SN_BLANK: return "SQL pcb serail number blank"                   // 0x50001006
    case .SL_MYSQL_PCB_SN_TOO_LONG: return "SQL pcb serial number too long"             // 0x50001007
    case .SL_MYSQL_MNEMONIC_BLANK: return "SQL mnemonic blank"                          // 0x50001008
    case .SL_MYSQL_MNEMONIC_TOO_LONG: return "SQL mnemonic too long"                    // 0x50001009
    case .SL_MYSQL_PCB_REV_BLANK: return "SQL pcb rev blank"                            // 0x5000100A
    case .SL_MYSQL_PCB_REV_TOO_LONG: return "SQL pcb rev too long"                      // 0x5000100B
    case .SL_MYSQL_PCB_MODEL_BLANK: return "SQL pcb model blank"                        // 0x5000100C
    case .SL_MYSQL_PCB_MODEL_TOO_LONG: return "SQL pcb model too long"                  // 0x5000100D
    case .SL_MYSQL_BAD_TESTID: return "SQL bad test id"                                 // 0x5000100E
    case .SL_MYSQL_PART_DESIG_BLANK: return "SQL part desig blank"                      // 0x5000100F
      
    case .SL_MYSQL_SW_NAME_BLANK: return "SQL sw name blank"                            // 0x50001010
    case .SL_MYSQL_SW_VERSION_BLANK: return "SQL sw version blank"                      // 0x50001011
    case .SL_MYSQL_BOM_REV_BLANK: return "SQL bom rev blank"                            // 0x50001012
    case .SL_MYSQL_BOM_REV_TOO_LONG: return "SQL bom rev too long"                      // 0x50001013
    case .SL_MYSQL_BOM_BLANK: return "SQL bom blank"                                    // 0x50001014
    case .SL_MYSQL_BOM_TOO_LONG: return "SQL bom too long"                              // 0x50001015
    case .SL_MYSQL_MODEL_BLANK: return "SQL model blank"                                // 0x50001016
    case .SL_MYSQL_MODEL_TOO_LONG: return "SQL model too long"                          // 0x50001017
      
      
    // Warning
    case .SLM_W_SERVICE: return "Service"                                               // 0x31000001
    case .SLM_W_NO_TRANSMITTER: return "No transmitter"                                 // 0x31000002
    case .SLM_W_INTERLOCK: return "Interlock"                                           // 0x31000003
    case .SL_W_NOTHING_TO_SEND: return "Nothing to send"                                // 0x31000004
    case .SLM_W_FPGA_TEMP_WARN: return "FPGA temperature"                               // 0x31000005
    case .SL_W_CWX_NO_MORE: return "CWX no more"                                        // 0x31000007
    case .SLM_W_DEFAULT_PROFILE: return "Default profile"                               // 0x31000008
    case .SL_W_ATU_MAX_POWER_INTERFERENCE: return "ATU max power interference"          // 0x31000009
      
      
    // Info
    case .SLM_I_CLIENT_CONNECTED: return "Client connected"                             // 0x10000001
    case .SLM_I_UNKNOWN_CLIENT: return "Unknown client"                                 // 0x10000002
    case .SL_I_CWX_NOTHING_TO_ERASE: return "CWX Nothing to erase"                      // 0x10000003
    }
  }
}

