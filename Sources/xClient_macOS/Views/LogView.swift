//
//  LogViewer.swift
//  xLibClient package
//
//  Created by Douglas Adams on 10/10/20.
//

import SwiftUI

/// A View to display the contents of the app's log
///
public struct LogView: View {
  @EnvironmentObject var logger: Logger

  let width : CGFloat = 1000

  public init() {
    
  }

  public var body: some View {

    VStack {
      ScrollView {
        ForEach(logger.logLines) { line in
          Text(line.text)
            .font(.system(size: CGFloat(logger.fontSize), weight: .regular, design: .monospaced))
            .frame(minWidth: width, maxWidth: .infinity, alignment: .leading)
        }
      }
      HStack {
        Picker(selection: $logger.level, label: Text("")) {
          ForEach(Logger.LogLevel.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }
        .frame(width: 150, height: 18, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        .padding(.leading, 10)
        .padding(.trailing, 20)
        
        Picker(selection: $logger.filterBy, label: Text("Filter By")) {
          ForEach(Logger.LogFilter.allCases, id: \.self) {
            Text($0.rawValue)
          }
        }
        .frame(width: 150, height: 18, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        
        TextField("Filter text", text: $logger.filterByText)
          .background(Color(.gray))
          .frame(width: 175, alignment: .leading)
          .padding(.trailing, 20)
        
        Toggle("Timestamps", isOn: $logger.showTimestamps).frame(width: 100, alignment: .leading)
        Button(action: {logger.loadLog() }) {Text("Load") }
        Button(action: {logger.saveLog() }) {Text("Save")}
        Spacer()
        Button(action: {logger.refresh() }) {Text("Refresh")}
        Button(action: {logger.delegate!.logWindowIsVisible = false }) {Text("Close")}.padding(.trailing, 20)
      }
      .padding(.bottom, 10)
    }
    .frame(minWidth: width, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
  }
}

public struct LogView_Previews: PreviewProvider {
    public static var previews: some View {
      LogView()
        .environmentObject( Logger.sharedInstance)
    }
}
