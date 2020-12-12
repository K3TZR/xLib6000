//
//  SmartLinkView.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/13/20.
//

import SwiftUI

/// Image, textfields and button for the SmartLink portion of the Picker
///   only shown if SmartLink is enabled
///
struct SmartLinkView: View {
  @EnvironmentObject var radioManager : RadioManager
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {

    VStack {
      HStack {
        ZStack {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
          if radioManager.smartLinkImage != nil {
            Image(nsImage: radioManager.smartLinkImage!)
              .resizable()
          }
        }
        .frame(width: 60, height: 60)
        .aspectRatio(8/8, contentMode: .fit)
        .cornerRadius(8)
        VStack{
          HStack {
            Text("Name:")
              .frame(width: 60, alignment: .trailing)
            TextField("Name:", text: $radioManager.smartLinkName)
              .background(Color(.textBackgroundColor))
              .frame(width: 200, alignment: .leading)
          }
          HStack {
            Text("Callsign:")
              .frame(width: 60, alignment: .trailing)
            TextField("Callsign:", text: $radioManager.smartLinkCallsign)
              .background(Color(.textBackgroundColor))
              .frame(width: 200, alignment: .leading)
          }
        }
        Button(action: {
          presentationMode.wrappedValue.dismiss()
          DispatchQueue.main.async { [self] in
            if radioManager.smartLinkIsLoggedIn {radioManager.smartLinkLogout() } else {radioManager.smartLinkLogin()}
          }
        }) {Text(radioManager.smartLinkIsLoggedIn ? "Logout" : "Login")}.disabled(!radioManager.delegate.smartLinkEnabled)
        .padding(.trailing, 20)
      }.frame(minHeight: 90, idealHeight: 90, maxHeight: 90)
    }
    
    Divider()
  }
}

struct SmartLinkView_Previews: PreviewProvider {
  static var previews: some View {
    SmartLinkView()
      .environmentObject(RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
  }
}
