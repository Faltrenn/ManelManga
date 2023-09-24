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
    
    func getSources(episodeLink: String, completion: @escaping (_ sources: [Source]) -> Void) {
        guard let url = URL(string: episodeLink) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .ascii) {
                do {
                    let sources = html.split(separator: "sources: ")[1].split(separator: "]")[0] + "]"
                    
                    let srcs = try JSONDecoder().decode([Source].self, from: Data(sources.description.utf8))
                    DispatchQueue.main.async {
                        completion(srcs)
                    }
                } catch { }
            }
        }.resume()
    }
    
    func downloadEpisode(anime: Anime, episode: Episode, source: Source, completion: @escaping (_ anime: Anime) -> Void) {
        print("foi")
        URLSession.shared.downloadTask(with: URL(string: source.file)!) { url, response, error in
            print("terminou")
            guard let fileURL = url else { return }
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                               in: .userDomainMask)[0]
                    .appendingPathComponent(anime.name, isDirectory: true)

                print("anime: ", anime.name)
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
                let savedURL = documentsURL.appendingPathComponent("\(episode.name) \(source.label).\(source.type.split(separator: "/")[1])")
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                if let animeId = self.animes.firstIndex(of: anime) {
                    var newAnime = self.animes[animeId]
                    if let episodeId = newAnime.episodes.firstIndex(of: episode) {
                        var newEpisode = newAnime.episodes[episodeId]
                        if source.label.hasPrefix("SD") {
                            newEpisode.downloads.SD = savedURL.lastPathComponent
                        } else if source.label.hasPrefix("HD"){
                            newEpisode.downloads.HD = savedURL.lastPathComponent
                        } else {
                            newEpisode.downloads.FHD = savedURL.lastPathComponent
                        }
                        newAnime.episodes[episodeId] = newEpisode
                        self.animes[animeId] = newAnime
                        DispatchQueue.main.async {
                            completion(self.animes[animeId])
                        }
                    }
                }
            } catch {
                print(error)
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

