//
//  EpisodeView.swift
//  ManelManga
//
//  Created by Emanuel on 20/09/23.
//

import SwiftUI
import AVKit

extension View {
    func unlockRotation() -> some View {
        onAppear {
            AppDelegate.orientationLock = UIInterfaceOrientationMask.allButUpsideDown
            UIViewController.attemptRotationToDeviceOrientation()
        }
        .onDisappear {
            AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}

struct EpisodeView: View {
    let anime: AnimeClass
    let episode: EpisodeClass
    
    @State var source: [Source] = []
    @State var choice: Source? = nil
    @State var player = AVPlayer()
    @State var play = false
    @State var seconds: Double = 0.0
    @State var fullscreen = false
    @State var hideControls = false
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            AnimePlayer(player: $player, play: $play, time: $seconds, fullscreen: $fullscreen, hideControls: $hideControls)
                .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                .fullScreenCover(isPresented: $fullscreen, content: {
                    AnimePlayer(player: $player, play: $play, time: $seconds, fullscreen: $fullscreen, hideControls: $hideControls)
                        .ignoresSafeArea()
                })
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
        if let episodeURL = anime.getDownloadedEpisodePath(episode: episode) {
            let asset = AVURLAsset(url: episodeURL)
            player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        } else {
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
}

#Preview {
    EpisodeView(anime: MainViewModel.shared.animes[1], episode: MainViewModel.shared.animes[1].episodes.first!)
}
