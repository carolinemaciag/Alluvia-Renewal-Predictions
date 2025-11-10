//
//  AlluviaApp.swift
//  Alluvia
//
//  Created by Pat Bradley on 10/12/25.
//

import SwiftUI

// This is the app's main entry point.
// It launches SplashView as the home screen.

// Main app struct required by SwiftUI
@main
struct AlluviaApp: App {
    // Scene group containing the app's main window
    var body: some Scene {
        WindowGroup {
            // Sets SplashView as the initial view for the app
            SplashView()
        }
    }
}
