//
//  AnimeView.swift
//  ManelManga
//
//  Created by Emanuel on 20/09/23.
//

import SwiftUI
import SwiftSoup

struct AnimeView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var anime: Anime
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack{
                    ForEach(Array(anime.episodes.enumerated()), id: \.offset) { c, episode in
                        NavigationLink {
                            EpisodeView(episode: episode)
                        } label: {
                            Text(episode.name)
                                .font(.title)
                        }
                    }
                }
            }
        }
        .onAppear {
            mainViewModel.getEpisodes(anime: anime) { episodes in
                anime.episodes = episodes
            }
        }
    }
}

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
