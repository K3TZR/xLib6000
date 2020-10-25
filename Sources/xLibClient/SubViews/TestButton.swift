//
//  TestButton.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/15/20.
//

import SwiftUI

/// Button with a red/green status indicator
///
struct TestButton: View {
  @EnvironmentObject var radioManager :RadioManager

  var body: some View {
    

    HStack {
      // only enable Test if a SmartLink connection is selected
      let testEnabled = radioManager.delegate.smartLinkEnabled && radioManager.pickerSelection.count > 0 && radioManager.pickerPackets[radioManager.pickerSelection.first!].type == .wan

      Button(action: { radioManager.testSmartLink() }) {Text("Test")}.disabled(!testEnabled)
        .padding(.horizontal, 20)
      Circle()
        .fill(radioManager.smartLinkTestStatus ? Color.green : Color.red)
        .frame(width: 20, height: 20)
        .padding(.trailing, 20)
    }
  }
}
  
  struct TestButton_Previews: PreviewProvider {
    static var previews: some View {
      TestButton()
        .environmentObject(RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
    }
  }
