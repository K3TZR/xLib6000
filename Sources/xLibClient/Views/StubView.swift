//
//  StubView.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/25/20.
//

import SwiftUI

/// A view to be inserted into the app's ContentView
///     allows display of the Picker and Auth0 sheets (supplied by xLibClient)
///
public struct StubView: View {
  @ObservedObject public var radioManager: RadioManager

  public init(radioManager: RadioManager) {
    self.radioManager = radioManager
  }

  public var body: some View {
    ZStack {
      Text("")
        .sheet(isPresented: $radioManager.showPickerSheet) {
          PickerView()
            .environmentObject(radioManager)
        }
      Text("")
        .sheet(isPresented: $radioManager.showAuth0Sheet ) {
          Auth0View()
            .environmentObject(radioManager)
        }
    }
  }
}

public struct StubView_Previews: PreviewProvider {
  public static var previews: some View {
    StubView(radioManager: RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
  }
}
