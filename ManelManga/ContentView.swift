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
    @ObservedObject var mainViewModel: MainViewModel = MainViewModel()
    @State var page: Pages = .Anime
    
    var body: some View {
        VStack {
            switch page {
            case .Anime:
                AnimeHomeView()
            case .Manga:
                MangaHomeView()
            }
            VStack {
                TabBar(page: $page)
            }
        }
        .environmentObject(mainViewModel)
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

struct DownloadTest: View {
    //let link = "https://cdn-2.tanoshi.digital/stream/T/Tomo-chan_wa_Onnanoko_Dublado/480p/AnV-01.mp4?md5=P8k_A0bgNKYihZINWueUyQ&expires=1695436648"
    let link = "https://cdn-1.tanoshi.digital/stream/B/Bastard_Ankoku_no_Hakaishin_Season_2_ONA_Dublado/480p/AnV-02.mp4?md5=DMLAtR94cr0--q9FiNHVBA&expires=1695440788"
    @State var downloadedURL:URL?
    
    var body: some View {
        VStack {
            Button("Download") {
                print("foi")
                URLSession.shared.downloadTask(with: URL(string: link)!) { url, response, error in
                    print("Terminou")
                    guard let fileURL = url else { return }
                    do {
                        let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                       in: .userDomainMask,
                                                                       appropriateFor: nil,
                                                                       create: false)
                        let savedURL = documentsURL.appendingPathComponent("Video2.mp4")
                        try FileManager.default.moveItem(at: fileURL, to: savedURL)
                        downloadedURL = savedURL
                    } catch {
                        print("erro: ", error)
                    }
                }.resume()
            }
            .font(.title)
            if let downloadedURL = downloadedURL {
                VStack {
                    Text(downloadedURL.absoluteString)
                    VideoPlayer(player: AVPlayer(asset: AVURLAsset(url: downloadedURL)))
                }
            }

        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
