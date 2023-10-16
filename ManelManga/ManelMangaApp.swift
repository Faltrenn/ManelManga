//
//  ManelMangaApp.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI

@main
struct ManelMangaApp: App {
    @ObservedObject var mainViewModel = MainViewModel.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mainViewModel)
        }
    }
}
