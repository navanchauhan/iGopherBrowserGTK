// The Swift Programming Language
// https://docs.swift.org/swift-book

import Adwaita

@main
struct iGopherBrowserGTK: App {
  let id = "com.navanchauhan.igopherbrowsergtk"
  var app: GTUIApp!

  var scene: Scene {
    Window(id: "main") { window in
      BrowserView(app: app)
        .topToolbar {
          ToolbarView(app: app, window: window)
        }
    }
    .defaultSize(width: 800, height: 800)
    .title("iGopherBrowser (GTK Version)")
  }
}
