//
//  RadioListView.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/13/20.
//

import SwiftUI

/// Display a List of available radios / stations
///
struct RadioListView : View {
  @EnvironmentObject var radioManager : RadioManager
  @Environment(\.presentationMode) var presentationMode
  
  // allow doubleClicking to select a radio
//  func doubleTap(_ id: Int) {
//    radioManager.pickerSelection.removeAll()
//    radioManager.pickerSelection.insert(id)
//    presentationMode.wrappedValue.dismiss()
//    radioManager.connectToSelection()
//  }
  
  func resetDefault(_ packet: PickerPacket, _ isGui: Bool) {
    for (i, _) in radioManager.pickerPackets.enumerated() {
      radioManager.pickerPackets[i].isDefault = false
    }
    if isGui {
      radioManager.delegate.defaultGuiConnection = ""
    } else {
      radioManager.delegate.defaultConnection = ""
    }
  }
  
  func setAsDefault(_ packet: PickerPacket, _ isGui: Bool) {
    resetDefault(packet, isGui)
    
    for (i, thisPacket) in radioManager.pickerPackets.enumerated() {
      // do type and serialNumber match?
      if packet == thisPacket {
        // YES, is this a Gui connection?
        if isGui {
          // YES
          radioManager.delegate.defaultGuiConnection = packet.connectionString
          radioManager.pickerPackets[i].isDefault = true
          
          // NO, it's a non-Gui connection, does the station match
        } else if packet.stations == thisPacket.stations {
          // YES
          radioManager.delegate.defaultConnection = packet.connectionString + "." + packet.stations
          radioManager.pickerPackets[i].isDefault = true
        }
      }
    }
  }
  
  var body: some View {
    
    VStack {
      HStack {
        Text("Type")
          .frame(width: 90, alignment: .leading)
        Text("Name")
          .frame(width: 150, alignment: .leading)
        Text("Status")
          .frame(width: 100, alignment: .leading)
        Text("Station(s)")
          .frame(width: 200, alignment: .leading)
      }.padding(.top, 10)
      
      Divider()

      HStack {
        List(radioManager.pickerPackets, id: \.id, selection: $radioManager.pickerSelection) { packet in
          let color : Color = packet.isDefault ? Color(.linkColor) : Color(.textColor)
          
          HStack{
            
            Text(packet.type == .local ? "LOCAL" : "SMARTLINK")
              .foregroundColor( color )
              .frame(width: 90, alignment: .leading)
            Text(packet.nickname)
              .foregroundColor( color )
              .frame(width: 150, alignment: .leading)
            Text(packet.status.rawValue)
              .foregroundColor( color )
              .frame(width: 100, alignment: .leading)
            Text(packet.stations)
              .foregroundColor( color )
              .frame(width: 200, alignment: .leading)
            Spacer()
          }
//          .onTapGesture(count: 2, perform: doubleTap(packet.id) )
          .contextMenu(menuItems: {
            Button(action: {setAsDefault(packet, radioManager.delegate.connectAsGui)}) {Text("Set as Default")}
            Button(action: {resetDefault(packet, radioManager.delegate.connectAsGui)}) {Text("Reset Default")}
          })
        }
      }
      .frame(width: 600, height: 150)
      .padding(.bottom, 0)
    }
  }
}

struct RadioListView_Previews: PreviewProvider {
  static var previews: some View {
    RadioListView()
      .environmentObject(RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
  }
}
