//
//  PixyApp.swift
//  Pixy
//
//  Created by Lorenzo Mazza on 15/03/25.
//

import SwiftUI

@main
struct PixelArtApp: App {
    var body: some Scene {
        WindowGroup {
            PixelArtGridView()
        }
        .windowStyle(.plain)
    }
}
