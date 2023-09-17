//
//  ManelMangaApp.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI

@main
struct ManelMangaApp: App {
    @ObservedObject var viewModel = MainViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
