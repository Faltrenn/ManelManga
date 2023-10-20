//
//  ContentView.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI
import SwiftSoup
import AVKit


struct ContentView: View {
    @State var page: Pages = .Manga
    
    var body: some View {
        NavigationStack {
            VStack {
                switch page {
                case .Anime:
                    AnimeHomeView()
                case .Manga:
                    MangaHomeView()
                }
                TabBar(page: $page)
            }
        }
    }
}

struct TabBar: View {
    @Binding var page: Pages
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(Pages.allCases, id: \.self) { p in
                VStack {
                    Image(systemName: page == p ? p.selIcon : p.unsIcon)
                        .font(.title)
                    Text(p.title)
                }
                .foregroundColor(page == p ? .blue : .gray)
                .onTapGesture {
                    page = p
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MainViewModel.shared)
}
