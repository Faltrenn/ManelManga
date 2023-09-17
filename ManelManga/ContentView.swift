//
//  ContentView.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI
import SwiftSoup

enum Pages {
    case Home, Manga, Volume
}

struct ContentView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        ZStack {
            switch mainViewModel.page {
            case .Home:
                HomeView()
            case .Manga:
                MangaView()
            case .Volume:
                VolumeView()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
