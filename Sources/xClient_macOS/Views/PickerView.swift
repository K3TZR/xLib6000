//
//  PickerView.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/15/20.
//

import SwiftUI

/// A View to allow the user to select a Radio / Station for connection
///
public struct PickerView: View {
  @EnvironmentObject var radioManager: RadioManager
  
  public init() {
  }
    
  public var body: some View {
      VStack {
        if radioManager.delegate.smartLinkEnabled { SmartLinkView() }
        RadioListView()
        PickerButtonsView()
      }.frame(width: 600)
    }
}

struct PickerView_Previews: PreviewProvider {
    static var previews: some View {
      PickerView().environmentObject(RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
    }
}
