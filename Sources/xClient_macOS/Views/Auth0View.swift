//
//  Auth0View.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/18/20.
//  Copyright © 2020 Douglas Adams. All rights reserved.
//

import SwiftUI
import WebKit

/// A View to display the SmartLink logon screen (an Auth0 screen)
///
public struct Auth0View: View {
  @EnvironmentObject var radioManager : RadioManager
  @Environment(\.presentationMode) var presentationMode
  
  public var body: some View {
    
    VStack {
      let auth0View = WebBrowserView(radioManager: radioManager)
      auth0View
        .onAppear() {
          auth0View.load(urlString: radioManager.wanManager!.auth0UrlString)
        }
      Button(action: {
        presentationMode.wrappedValue.dismiss()
        radioManager.cancelButton()
      }) { Text("Cancel")}
    }.frame(width: 740, height: 350, alignment: .leading)
    .padding(.vertical, 10)
  }
}

public struct Auth0View_Previews: PreviewProvider {
  public static var previews: some View {
    Auth0View()
      .environmentObject(RadioManager(delegate: MockRadioManagerDelegate(), domain: "net.k3tzr", appName: "xApi6000"))
  }
}

// ----------------------------------------------------------------------------
// MARK: - Encapsulation of WKWebView for SwiftUI

public struct WebBrowserView {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var radioManager: RadioManager

  var webView = WKWebView()
  
  func auth0LoginSuccess(idToken: String, refreshToken: String) {
    radioManager.wanManager!.processAuth0Tokens(idToken: idToken, refreshToken: refreshToken)
    radioManager.wanManager!.closeAuth0LoginView()
  }
  
  func load(urlString: String) {
    if let url = URL(string: urlString) {      
      let urlRequest = URLRequest(url: url)
      webView.load( urlRequest)
    }
  }
  
  public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    
    var parent: WebBrowserView
    
    private let kKeyIdToken       = "id_token"
    private let kKeyRefreshToken  = "refresh_token"
    
    init(parent: WebBrowserView) {
      self.parent = parent
    }
    
    public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) {
      // ...
    }
    
    public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
      let nsError = (withError as NSError)
      if (nsError.domain == "WebKitErrorDomain" && nsError.code == 102) || (nsError.domain == "WebKitErrorDomain" && nsError.code == 101) {
        // Error code 102 "Frame load interrupted" is raised by the WKWebView
        // when the URL is from an http redirect. This is a common pattern when
        // implementing OAuth with a WebView.
        return
      }
    }
    
    //    public func webView(_: WKWebView, didFinish: WKNavigation!) {
    //      // ...
    //      print("Coordinator: Auth0: didFinish \(String(describing: didFinish))")
    //    }
    //
    //    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    //      // ...
    //      print("Coordinator: Auth0: didStartProvisionalNavigation: \(String(describing: navigation))")
    //    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      
      // does the navigation action's request contain a URL?
      if let url = navigationAction.request.url {
        
        // YES, is there a token inside the url?
        if url.absoluteString.contains(kKeyIdToken) {
          
          // extract the tokens
          var responseParameters = [String: String]()
          if let query = url.query { responseParameters += query.parametersFromQueryString }
          if let fragment = url.fragment, !fragment.isEmpty { responseParameters += fragment.parametersFromQueryString }
          
          // did we extract both tokens?
          if let idToken = responseParameters[kKeyIdToken], let refreshToken = responseParameters[kKeyRefreshToken] {
            
            // YES, pass them back
            parent.auth0LoginSuccess(idToken: idToken, refreshToken: refreshToken)
          }
          decisionHandler(.cancel)
          
          return
        }
      }
      decisionHandler(.allow)
    }
    
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
      if navigationAction.targetFrame == nil {
        webView.load(navigationAction.request)
      }
      return nil
    }
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }
}

extension WebBrowserView: NSViewRepresentable {
  
  public typealias NSViewType = WKWebView
  
  public func makeNSView(context: NSViewRepresentableContext<WebBrowserView>) -> WKWebView {
    
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    return webView
  }
  
  public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<WebBrowserView>) {
    
  }
}

