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
      Text(params.title)
      Spacer()
      Text(params.message)
      Divider().padding([.leading, .trailing], 40)
      HStack {
        ForEach(params.buttons.indices, id: \.self) { i in
          Button(params.buttons[i].text) {
            (params.buttons[i].action ?? {})()
            self.presentation.wrappedValue.dismiss()
          }
          .padding()
        }
      }
    }.padding(.top, 20)
  }
}

struct AlertView_Previews: PreviewProvider {
  static var previews: some View {
    AlertView(params: AlertParams(style: .warning, title: "Sample Title", message: "A Message", buttons: [("Ok", nil)]))
  }
}
