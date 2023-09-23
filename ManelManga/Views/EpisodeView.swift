//
//  EpisodeView.swift
//  ManelManga
//
//  Created by Emanuel on 20/09/23.
//

import SwiftUI
import AVKit
import VideoPlayer

struct EpisodeView: View {
    let episode: Episode
    @State var source: [Source] = []
    @State var choice: Source? = nil
    @State var player = AVPlayer()
    @State var play = false
    @State var seconds: Double = 0.0
    @State var fullscreen = false
    @State var hideControls = false
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var teste: AVRouteDetector = AVRouteDetector()
    
    var body: some View {
        VStack {
            AnimePlayer(player: $player, play: $play, time: $seconds, fullscreen: $fullscreen, hideControls: $hideControls)
                .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
            Spacer()
        }
        .onReceive(timer) { newValue in
            seconds = player.currentTime().seconds
        }
        .onAppear {
            getEpisode()
        }
        .onDisappear {
            play = false
            player.pause()
        }
    }
    
    func getEpisode() {
        guard let url = URL(string: episode.videoLink) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .ascii) {
                do {
                    let sources = html.split(separator: "sources: ")[1].split(separator: "]")[0] + "]"
                    
                    source = try JSONDecoder().decode([Source].self, from: Data(sources.description.utf8))
                    choice = source[0]
                    if let url = URL(string: choice!.file) {
                        player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    }
                } catch { }
            }
        }.resume()
    }
}

struct EpisodeView_Previews: PreviewProvider {
    static var previews: some View {
//        ContentView()
        EpisodeView(episode: Episode(name: "", thumb: "", videoLink: "https://animes.vision/animes/bleach-sennen-kessen-hen-ketsubetsu-tan/episodio-03/legendado", downloadedVideoPath: nil, visualized: false))
    }
}
