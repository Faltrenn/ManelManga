//
//  CustomPlayer.swift
//  ManelManga
//
//  Created by Emanuel on 21/09/23.
//

import SwiftUI
import AVKit

struct CustomPlayer: UIViewControllerRepresentable {
    typealias UIViewControllerType = AVPlayerViewController
    @Binding var player: AVPlayer
    @Binding var play: Bool
    @Binding var fullscreen: Bool
    @Binding var time: Double
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.allowsExternalPlayback = true
        
        controller.player = player
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) { }
}

struct AnimePlayer: View {
    @Binding var player: AVPlayer
    @Binding var play: Bool
    @Binding var time: Double
    @Binding var fullscreen: Bool
    @Binding var hideControls: Bool
    
    var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        CustomPlayer(player: $player, play: $play, fullscreen: $fullscreen, time: $time)
            .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
            .onTapGesture {
                hideControls.toggle()
            }
            .overlay {
                CustomPlayerControls(fullscreen: self.$fullscreen, play: self.$play, time: self.$time, hideControls: $hideControls)
            }.onReceive(timer) { _ in
                time = self.player.currentTime().seconds
            }
            .onChange(of: play) { newValue in
                if newValue {
                    player.play()
                } else {
                    player.pause()
                }
            }
    }
}

struct AirPlayView: UIViewRepresentable {
    func updateUIView(_ uiView: UIViewType, context: Context) { }
    
    func makeUIView(context: Context) -> some UIView {
        let routePick = AVRoutePickerView()
        routePick.backgroundColor = .clear
        routePick.activeTintColor = .blue
        routePick.tintColor = .gray
        routePick.prioritizesVideoDevices = true
        
        return routePick
    }
}

struct CustomPlayerControls: View {
    @Binding var fullscreen: Bool
    @Binding var play: Bool
    @Binding var time: Double
    @Binding var hideControls: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(hideControls ? 0 : 0.2)
                .onTapGesture {
                    hideControls.toggle()
                }
            Image(systemName: play ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 35, height: 35)
                .onTapGesture {
                    play.toggle()
                }
                .zIndex(1)
            VStack {
                HStack {
                    Image(systemName: fullscreen ? "arrow.down.right.and.arrow.up.left": "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .onTapGesture {
                            fullscreen.toggle()
                        }
                    Spacer()
                }
                Spacer()
                HStack {
                    Text(getTime(timeInSeconds: time))
                    Spacer()
                    Text(getTime(timeInSeconds: 20))
                    AirPlayView()
                        .frame(width: 40, height: 40)
                }
            }
            .padding()
        }
        .foregroundColor(.white)
        .opacity(hideControls ? 0 : 1)
    }
    
    func getTime(timeInSeconds: Double) -> String {
        var minutes: Double = 0
        var seconds: Double = 0
        if !timeInSeconds.isNaN {
            minutes = timeInSeconds / 60
            seconds = timeInSeconds.truncatingRemainder(dividingBy: 60)
        }
        return String(format: "%02.0f:%02.0f", minutes, seconds)
        
    }
}

struct Preview: View {
    @State var player = AVPlayer(url: URL(string: "https://cdn-1.tanoshi.digital/stream/B/Bleach__Sennen_Kessen-hen_-_Ketsubetsu-tan/480p/AnV-03.mp4?md5=NZBsPvtl-D8cmFTIhBNvlg&expires=1695327055")!)
    @State var play = false
    @State var time: Double = 0
    @State var fullscreen = false
    @State var hideControls = false
    var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            AnimePlayer(player: $player, play: $play, time: $time, fullscreen: $fullscreen, hideControls: $hideControls)
            Spacer()
        }
    }
}


struct CustomPlayer_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
}
