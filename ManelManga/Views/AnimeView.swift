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
                VStack {
                    HStack {
                        AsyncImage(url: URL(string: anime.image)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 175)
                        } placeholder: {
                            ProgressView()
                        }
                        VStack {
                            Text(anime.name)
                                .font(.title2)
                                .bold()
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity)
                            Spacer()
                        }
                    }
                    Text("Episodios")
                        .font(.title)
                        .bold()
                    ForEach(Array(anime.episodes.enumerated()), id: \.offset) { c, episode in
                        NavigationLink {
                            EpisodeView(episode: episode)
                        } label: {
                            EpisodeCard(episode: episode)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct EpisodeCard: View {
    let episode: Episode
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: episode.thumb)) { image in
                image
                    .resizable()
                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                    .frame(maxWidth: 150)
                    .overlay {}
            } placeholder: {
                Rectangle()
                    .fill(.gray)
                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                    .frame(maxWidth: 150)
                    .overlay {
                        ProgressView()
                    }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(episode.name)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.leading)
                HStack(spacing: 25) {
                    Spacer()
                    if episode.downloadedVideoPath == nil {
                        Button {
                            
                        } label: {
                            Menu {
                                Button("1080p") { }
                                Button("720p") { }
                                Button("480p") { }
                            } label: {
                                Image(systemName: "arrow.down.to.line")
                                    .bold()
                            }
                        }
                    } else {
                        Button {
                            
                        } label: {
                            Menu {
                                Button("Apagar download") { }
                            } label: {
                                Image(systemName: "arrow.down.to.line")
                                    .bold()
                                    .overlay {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .offset(CGSize(width: 10, height: -10))
                                    }
                            }
                        }

                    }
                    Image(systemName: "ellipsis")
                        .bold()
                }
                .font(.title2)
            }
        }
    }
}

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
//        ContentView()
        AnimeView(anime: Anime(name: "Jujutsu Kaisen 2nd Season",
                               image: "https://animes.vision/storage/capa/WpyWcVumukyDxU4NOxiDzhdOZksAho2sWR23Fnzx.jpg",
                               link: "https://animes.vision/animes/one-piece",
                               episodes: [
                                Episode(name: "Name",
                                        thumb: "https://animes.vision/storage/screenshot/I9hvBcj20yfzZS4P0FYHdpB6D9fBoKoiTUEPAW9I.jpg",
                                        videoLink: "https://animes.vision/animes/jujutsu-kaisen-2nd-season/episodio-05/legendado",
                                        downloadedVideoPath: "",
                                        visualized: false),
                                Episode(name: "Name2",
                                        thumb: "https://animes.vision/storage/screenshot/2t7fJaUHcfHnOIThKZ21ICKa4E7kO98zqh5hPYyW.jpg",
                                        videoLink: "https://animes.vision/animes/jujutsu-kaisen-2nd-season/episodio-09/legendado",
                                        downloadedVideoPath: nil,
                                        visualized: false)
                               ]))
            .environmentObject(MainViewModel())
    }
}
