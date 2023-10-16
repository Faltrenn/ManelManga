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
    
    @Published private(set) var mangas: [MangaClass] = []
    
    static var shared = MainViewModel()
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "animes") {
            do {
                self.animes = try JSONDecoder().decode([Anime].self, from: data)
            } catch { }
        }
        
        if let data = UserDefaults.standard.data(forKey: "mangas") {
            do {
                for manga in try JSONDecoder().decode([Manga].self, from: data) {
                    self.mangas.append(manga.getClass())
                }
            } catch { }
        }
    }
    
    func addManga(mangaLink: String) {
        guard let url = URL(string: mangaLink) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let doc = try SwiftSoup.parse(html)
                    
                    let name = try doc.select("div[class=manga_sinopse] h2").text()
                    
                    let image = try doc.select("div[class=serie-capa] img").attr("src")
                    
                    let volumesElements = try doc.select("li[class=row lista_ep] a").array()
                    
                    var volumes: [Volume] = []
                    for volume in volumesElements {
                        volumes.append(Volume(name: try volume.text(), link: try volume.attr("href"), images: [], downloadedImages: [], downloaded: false))
                    }
                    
                    DispatchQueue.main.async {
                        self.mangas.append(Manga(name: name, image: image, link: mangaLink, volumes: volumes).getClass())
                        self.saveMangas()
                    }
                } catch { }
            }
        }.resume()
    }
    
    func removeManga(manga: MangaClass) {
        self.mangas.remove(at: self.mangas.firstIndex(of: manga)!)
        self.saveMangas()
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
                if let episode = self.getEpisode(epElement: epElement) {
                    episodes.append(episode)
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
        print("Foi")
        URLSession.shared.downloadTask(with: URL(string: source.file)!) { url, response, error in
            print("Terminou")
            guard let fileURL = url else { return }
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                               in: .userDomainMask)[0]
                    .appendingPathComponent(anime.name, isDirectory: true)
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
            var mangas: [Manga] = []
            for manga in self.mangas {
                mangas.append(manga.getStruct())
            }
            UserDefaults().set(try JSONEncoder().encode(mangas), forKey: "mangas")
        } catch { }
    }
}

