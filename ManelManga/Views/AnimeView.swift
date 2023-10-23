//
//  AnimeView.swift
//  ManelManga
//
//  Created by Emanuel on 20/09/23.
//

import SwiftUI
import SwiftSoup

struct AnimeView: View {
    @State var anime: AnimeClass
    
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
    @Binding var anime: AnimeClass
    let episode: EpisodeClass
    @State var sources: [Source]?
    
    @State var downloading: Bool = false
    @State var progress: CGFloat = .zero
    
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
                                        AnimeURLSession.shared.addEpisodeToQueue(anime: anime, episode: episode, source: source, downloading: $downloading, progress: $progress)
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
                                        if downloading {
                                            Circle()
                                                .stroke(.gray, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                                .rotationEffect(Angle(degrees: -90))
                                            Circle()
                                                .trim(from: 0, to: progress)
                                                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                                .rotationEffect(Angle(degrees: -90))
                                                .animation(.easeIn(duration: 0.15), value: progress)
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
                }
                .font(.title2)
            }
        }
        .onAppear {
            MainViewModel.shared.getSources(episodeLink: episode.videoLink) { sources in
                self.sources = sources
            }
        }
    }
}

#Preview {
    AnimeView(anime: MainViewModel.shared.animes[2])
}
