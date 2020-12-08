//
//  AlertView.swift
//  xApi6000
//
//  Created by Douglas Adams on 12/5/20.
//

import SwiftUI

struct AlertView: View {
  @Environment(\.presentationMode) var presentation

  let params : AlertParams
  
  var body: some View {

    VStack {
      Text(params.title).font(.system(size: 16)).padding(.bottom, 10)
      Spacer()
      Text(params.message).font(.system(size: 12, weight: .regular, design: .monospaced))
      Divider().padding(.bottom, 10)
      HStack {
        ForEach(params.buttons.indices, id: \.self) { i in
          Button(params.buttons[i].text) {
            (params.buttons[i].action ?? {})()
            self.presentation.wrappedValue.dismiss()
          }
          .padding(.horizontal, 20)
        }
      }
    }.padding(20)
  }
}

struct AlertView_Previews: PreviewProvider {
  static var previews: some View {
    AlertView(params: AlertParams(style: .warning,
                                  title: "Sample Title",
                                  message:
"""
A sample Message
with 2 lines and 3 buttons
"""
                                  , buttons: [("Button1", nil), ("Button2", nil), ("Button3", nil)]))
  }
}
