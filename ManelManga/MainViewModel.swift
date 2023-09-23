//
//  MainViewModel.swift
//  ManelManga
//
//  Created by Emanuel on 22/09/23.
//

import Foundation
import SwiftUI
import SwiftSoup

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
                    self.saveAnimes()
                }
            }
        }
    }
    
    @Published private var _mangas: [Manga] = []
    var mangas: [Manga] {
        get {
            return _mangas
        }
        set(newValue) {
            if _mangas != newValue {
                DispatchQueue.main.async {
                    self._mangas = newValue
                    self.saveMangas()
                }
            }
        }
    }
    
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
    
    func getEpisode(epElement: Element) -> Episode? {
        do {
            let name = try epElement.select("div h3").text()
            let thumb = try epElement.select("a img").attr("src")
            let videoLink = try epElement.select("a").attr("href")
            return Episode(name: name, thumb: thumb, videoLink: videoLink, visualized: false)
        } catch { }
        return nil
    }
    
    func getAnime(html: String) -> Anime? {
        do {
            let doc = try SwiftSoup.parse(html)
            let name = try doc.select("h2[class=film-name dynamic-name]").text()
            let image = try doc.select("div[class=anisc-poster] div img").attr("src")
            var episodes: [Episode] = []
            
            let mainElement = try doc.select("div[class=screen-items]").first()!
            let epsElements = try mainElement.select("div[class=item]").array()
            for epElement in epsElements {
                if let episode = self.getEpisode(epElement: epElement) {                            episodes.append(episode)
                }
            }
            return Anime(name: name, image: image, link: doc.getBaseUri(), episodes: episodes)
        } catch { }
        
        return nil
    }
    
    func addAnime(animelink: String) {
        guard let url = URL(string: animelink) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                if let anime = self.getAnime(html: html) {
                    self.animes.append(anime)
                }
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

struct Teste_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

