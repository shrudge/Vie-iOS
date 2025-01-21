//
//  VieApp.swift
//  Vie
//
//  Created by Meet Balani on 30/11/24.
//

import SwiftUI

@main
struct VieApp: App {
    init() {
        print("Loading color database...")
        ColorDatabase.loadColors(from: "colors")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
