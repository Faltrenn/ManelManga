//
//  ContentView.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI
import SwiftSoup
import AVKit


class MainViewModel: ObservableObject {
    @Published private var _animes: [Anime] = []
    
    var animes: [Anime] {
        get {
            return _animes
        }
        set(newValue) {
            if _animes != newValue {
                DispatchQueue.main.async {
                    self._animes = newValue
                }
                saveAnimes()
            }
        }
    }
    @Published var mangas: [Manga] = []
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "animes") {
            do {
                self.animes = try JSONDecoder().decode([Anime].self, from: data)
            } catch { }
        }
        
        if let data = UserDefaults.standard.data(forKey: "mangas") {
            do {
                self.mangas = try JSONDecoder().decode([Manga].self, from: data)
            } catch { }
        }
    }
    
    func addAnime(animelink: String) {
        guard let url = URL(string: animelink) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let doc = try SwiftSoup.parse(html)
                    
                    let name = try doc.select("h2[class=film-name dynamic-name]").text()
                    
                    let image = try doc.select("div[class=anisc-poster] div img").attr("src")
                    
                    self.animes.append(Anime(name: name, image: image, link: animelink, episodes: []))

                } catch { }
            }
        }.resume()
    }
    
    func getEpisodes(anime: Anime, completion: @escaping (_ episodes: [Episode]) -> Void) {
        guard let url = URL(string: anime.link) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .ascii) {
                do {
                    let doc = try SwiftSoup.parse(html)
                    let element = try doc.select("div[class=screen-items]").first()!
                    var episodes: [Episode] = []
                    let names = try element.select("div h3").array()
                    let thumbs = try element.select("img").array()
                    let eps = try element.select("a[class=screen-item-thumbnail")

                    for ep in 0 ..< eps.count {
                        let name = try names[ep].text()
                        let thumb = try thumbs[ep].text()
                        let videoLink = try eps[ep].attr("href")
                        episodes.append(Episode(name: name, thumb: thumb, videoLink: videoLink, visualized: false))
                    }
                    DispatchQueue.main.async {
                        if let id = self.animes.firstIndex(where: { $0 == anime }) {
                            self.animes[id].episodes = episodes
                            completion(episodes)
                        }
                    }
                } catch { }
            }
        }.resume()
    }
    
    func saveAnimes() {
        do {
            UserDefaults().set(try JSONEncoder().encode(self.animes), forKey: "animes")
        } catch { }
    }
    
    func saveMangas() {
        do {
            UserDefaults().set(try JSONEncoder().encode(self.mangas), forKey: "mangas")
        } catch { }
    }
}

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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
