//
//  PickerButtonsView.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/13/20.
//

import SwiftUI

/// Picker buttons to Test, Close or Select
///
struct PickerButtonsView: View {
  @EnvironmentObject var radioManager : RadioManager
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    HStack {
      TestButton()
        .environmentObject(radioManager)
      Spacer()
      Button(action: {
        presentationMode.wrappedValue.dismiss()
        radioManager.closePicker()
      }) {Text("Close")}
        .frame(width: 50, alignment: .center)

      Spacer()
      Button(action: {
        presentationMode.wrappedValue.dismiss()
        radioManager.connectToSelection()
      }) {Text("Connect")}
      .disabled(radioManager.pickerSelection.isEmpty)
      .padding(.trailing, 20)
    }
    .padding(.bottom, 10)
  }
}

struct PickerButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        PickerButtonsView()
          .environmentObject(RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
    }
}
