//
//  BrowserView.swift
//
//
//  Created by Navan Chauhan on 7/27/24.
//

import Adwaita
import Foundation
import GopherHelpers
import swiftGopherClient

public func getHostAndPort(
  from urlString: String, defaultPort: Int = 70, defaultHost: String = "gopher.navan.dev"
) -> (host: String, port: Int, selector: String) {
  if let urlComponents = URLComponents(string: urlString),
    let host = urlComponents.host
  {
    let port = urlComponents.port ?? defaultPort
    let selector = urlComponents.path
    return (host, port, selector)
  } else {
    // Fallback for simpler formats like "localhost:8080"
    let components = urlString.split(separator: ":")
    let host = components.first.map(String.init) ?? defaultHost

    var port = (components.count > 1 ? Int(components[1]) : nil) ?? defaultPort
    var selector = "/"

    if components.count > 1 {
      let portCompString = components[1]
      let portCompComponents = portCompString.split(separator: "/", maxSplits: 1)
      if portCompComponents.count > 1 {
        port = Int(portCompComponents[0]) ?? defaultPort
        selector = "/" + portCompComponents[1]

      } else if portCompComponents.count == 1 {
        port = Int(portCompComponents[0]) ?? defaultPort
      }
    }

    return (host, port, selector)
  }
}

struct GopherNode: Identifiable, Equatable {
  static func == (lhs: GopherNode, rhs: GopherNode) -> Bool {
    return lhs.host == rhs.host && lhs.port == rhs.port && lhs.selector == rhs.selector
  }

  let id = UUID()
  var host: String
  let port: Int
  var selector: String
  var message: String?
  let item: gopherItem?
  var children: [GopherNode]?
}

struct BrowserView: View {
  var app: GTUIApp

  @State private var backwardStack: [GopherNode] = []
  @State private var forwardStack: [GopherNode] = []

  @State var url: String = "gopher://gopher.navan.dev:70"
  @State private var gopherItems: [gopherItem] = []

  let client = GopherClient()

  var view: Body {
    ScrollView {
      List(.init(gopherItems.indices), selection: nil) { idx in
        if gopherItems[idx].parsedItemType == .info {
          Text(gopherItems[idx].message)
            //                        .frame(minHeight: 20)
            .halign(.start)
            .padding(10, .leading)
        } else if gopherItems[idx].parsedItemType == .directory {
          Button(gopherItems[idx].message) {
            performGopherRequest(
              host: gopherItems[idx].host, port: gopherItems[idx].port,
              selector: gopherItems[idx].selector)
          }
        } else {
          Text(gopherItems[idx].message)
        }

      }
    }
    .topToolbar {
      HStack {
        Button(icon: .default(icon: .goPrevious)) {
          if let curNode = backwardStack.popLast() {
            forwardStack.append(curNode)
            if let prevNode = backwardStack.popLast() {
              performGopherRequest(
                host: prevNode.host, port: prevNode.port, selector: prevNode.selector,
                clearForward: false)
            }
          }
        }
        .padding()
        Button(icon: .default(icon: .goNext)) {
          if let nextNode = forwardStack.popLast() {
            performGopherRequest(
              host: nextNode.host, port: nextNode.port, selector: nextNode.selector,
              clearForward: false)
          }
        }
        .padding()
        EntryRow("Enter a URL", text: $url)
          .suffix {
            Button(icon: .default(icon: .editCopy)) { State<Any>.copy(url) }
              .flat()
              .verticalCenter()
          }
          .padding(10)
        Button("Go") {
          performGopherRequest(clearForward: false)
        }
      }
    }
    .onAppear {
      performGopherRequest()
    }
  }

  private func performGopherRequest(
    host: String = "", port: Int = -1, selector: String = "", clearForward: Bool = true
  ) {
    var res = getHostAndPort(from: self.url)

    if host != "" {
      res.host = host
      if selector != "" {
        res.selector = selector
      } else {
        res.selector = ""
      }
    }

    if port != -1 {
      res.port = port
    }

    self.url = "\(res.host):\(res.port)\(res.selector)"
    client.sendRequest(to: res.host, port: res.port, message: "\(res.selector)\r\n") { result in
      switch result {
      case .success(let resp):
        self.gopherItems = resp
        let newNode = GopherNode(
          host: res.host, port: res.port, selector: selector, item: nil,
          children: convertToHostNodes(resp))
        backwardStack.append(newNode)
        if clearForward {
          forwardStack.removeAll()
        }
      case .failure(let error):
        self.gopherItems = [
          gopherItem(rawLine: "Error \(error)")
        ]
      }
    }
  }

  private func convertToHostNodes(_ responseItems: [gopherItem]) -> [GopherNode] {
    var returnItems: [GopherNode] = []
    responseItems.forEach { item in
      if item.parsedItemType != .info {
        returnItems.append(
          GopherNode(
            host: item.host, port: item.port, selector: item.selector, message: item.message,
            item: item, children: nil))
      }
    }
    return returnItems
  }
}
