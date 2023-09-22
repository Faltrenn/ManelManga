//
//  AnimeView.swift
//  ManelManga
//
//  Created by Emanuel on 20/09/23.
//

import SwiftUI
import SwiftSoup

struct AnimeView: View {
    let anime: Anime
    @State var episodes: [Episode] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack{
                    ForEach(episodes, id: \.self) { episode in
                        NavigationLink{
                            EpisodeView(link: episode.videoLink)
                        } label: {
                            Text(episode.name)
                                .font(.title)
                        }
                    }
                }
            }
        }
        .onAppear {
            getEpisodes()
        }
    }
    
    func getEpisodes() {
        guard let url = URL(string: anime.link) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .ascii) {
                do {
                    let doc = try SwiftSoup.parse(html)
                    let elements = try doc.select("div[class=screen-items]")
                    var episodes: [Episode] = []
                    for element in elements.array() {
                        let name = try element.select("div h3").first()!.text()
                        let thumb = try element.select("img").first()!.attr("src")
                        let videoLink = try element.select("a[class=screen-item-thumbnail").first()!.attr("href")
                        episodes.append(Episode(name: name, thumb: thumb, videoLink: videoLink, visualized: false))
                    }
                    DispatchQueue.main.async {
                        self.episodes = episodes
                    }
                } catch { }
            }
        }.resume()
    }
}

struct AnimeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
