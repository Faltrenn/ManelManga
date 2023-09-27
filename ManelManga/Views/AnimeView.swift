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
                            EpisodeView(anime: anime, episode: episode)
                        } label: {
                            EpisodeCard(anime: $anime, episode: episode)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct EpisodeCard: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Binding var anime: Anime
    let episode: Episode
    @State var sources: [Source]?
    
    @ObservedObject var session = CustomURLSession()
    
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
                    
                    if let sources = sources {
                        Button { } label: {
                            Menu {
                                ForEach(sources, id: \.self) { source in
                                    Button {
                                        session.downloadEpisode(anime: anime, episode: episode, source: source) { savedAt in
                                            var to = anime
                                            to.episodes[to.episodes.firstIndex(of: episode)!].downloads.set(source: source, url: savedAt)
                                            mainViewModel.modifyAnime(target: anime, to: to)
                                            //MARK: Testar
                                        }
                                    } label: {
                                        Label("Baixar \(source.label)", systemImage: "arrow.down.to.line")
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.title3)
                                    .bold()
                                    .padding(5)
                                    .overlay {
                                        if session.downloadTask != nil {
                                            Circle()
                                                .stroke(.gray, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                                .rotationEffect(Angle(degrees: -90))
                                            Circle()
                                                .trim(from: 0, to: session.progress)
                                                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                                .rotationEffect(Angle(degrees: -90))
                                                .animation(.easeIn(duration: 0.15), value: session.progress)
                                        }
                                        if episode.downloads.get() != nil {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .offset(CGSize(width: 10, height: -10))
                                        }
                                    }
                            }
                        }
                    }
                    Image(systemName: "ellipsis")
                        .bold()
                        .onTapGesture {
                            session.resume()
                        }
                }
                .font(.title2)
            }
        }
        .onAppear {
            mainViewModel.getSources(episodeLink: episode.videoLink) { sources in
                self.sources = sources
            }
        }
    }
}

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
//        AnimeView(anime: Anime(name: "Jujutsu Kaisen 2nd Season",
//                               image: "https://animes.vision/storage/capa/WpyWcVumukyDxU4NOxiDzhdOZksAho2sWR23Fnzx.jpg",
//                               link: "https://animes.vision/animes/one-piece",
//                               episodes: [
//                                Episode(name: "Name",
//                                        thumb: "https://animes.vision/storage/screenshot/I9hvBcj20yfzZS4P0FYHdpB6D9fBoKoiTUEPAW9I.jpg",
//                                        videoLink: "https://animes.vision/animes/jujutsu-kaisen-2nd-season/episodio-05/legendado",
//                                        downloads: DownloadedVideo()),
//                                Episode(name: "Name2",
//                                        thumb: "https://animes.vision/storage/screenshot/2t7fJaUHcfHnOIThKZ21ICKa4E7kO98zqh5hPYyW.jpg",
//                                        videoLink: "https://animes.vision/animes/jujutsu-kaisen-2nd-season/episodio-09/legendado",
//                                        downloads: DownloadedVideo(SD: nil, HD: "", FHD: ""))
//                               ]))
//            .environmentObject(MainViewModel())
    }
}
