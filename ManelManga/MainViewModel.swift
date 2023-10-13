//
//  MainViewModel.swift
//  ManelManga
//
//  Created by Emanuel on 22/09/23.
//

import Foundation
import SwiftUI
import SwiftSoup

class AnimeClass: ObservableObject {
    var name: String
    var image: String
    var link: String
    @Published var episodes: [Episode]
    
    init(anime: Anime) {
        self.name = anime.name
        self.image = anime.image
        self.link = anime.link
        self.episodes = anime.episodes
    }
}

class EpisodeClass: ObservableObject {
    var name: String
    var thumb: String
    var videoLink: String
    var downloads: DownloadedVideo = DownloadedVideo()
    var visualized: Bool = false
    
    init(episode: Episode) {
        self.name = episode.name
        self.thumb = episode.thumb
        self.videoLink = episode.videoLink
        self.downloads = episode.downloads
        self.visualized = episode.visualized
    }
    
    func getStruct() -> Episode {
        return Episode(name: self.name, thumb: self.thumb, videoLink: self.videoLink, downloads: self.downloads, visualized: self.visualized)
    }
}
struct Manga: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var volumes: [Volume]
    
    func getClass() -> MangaClass {
        return MangaClass(manga: self)
    }
}

struct Volume: Codable, Hashable{
    var name: String
    var link: String
    var images: [URL]
    var downloadedImages: [String]
    var downloaded: Bool
    
    func getClass() -> VolumeClass {
        return VolumeClass(volume: self)
    }
}

class MangaClass: ObservableObject, Hashable {
    static func == (lhs: MangaClass, rhs: MangaClass) -> Bool {
        return lhs.getStruct() == rhs.getStruct()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    
    var name: String
    var image: String
    var link: String
    @Published var volumes: [VolumeClass]
    
    init(manga: Manga) {
        self.name = manga.name
        self.image = manga.image
        self.link = manga.link
        self.volumes = []
        for volume in manga.volumes {
            volumes.append(volume.getClass())
        }
    }
    
    func getStruct() -> Manga {
        var volumes: [Volume] = []
        for volume in self.volumes {
            volumes.append(volume.getStruct())
        }
        return Manga(name: self.name, image: self.image, link: self.link, volumes: volumes)
    }
}

class VolumeClass: ObservableObject, Hashable {
    static func == (lhs: VolumeClass, rhs: VolumeClass) -> Bool {
        return lhs.name == rhs.name && lhs.link == rhs.link
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    
    var name: String
    var link: String
    @Published var images: [URL]
    @Published var downloadedImages: [String]
    @Published var downloaded: Bool
    
    init(volume: Volume) {
        self.name = volume.name
        self.link = volume.link
        self.images = volume.images
        self.downloadedImages = volume.downloadedImages
        self.downloaded = volume.downloaded
    }
    
    func getImages(completion: (() -> Void)? = nil) {
        guard let url = URL(string: link) else { return }
        self.images = []
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let imagesLinks = html.split(separator: "\\\"images\\\": ")[1].split(separator: "}")[0].replacing("\\", with: "")
                    let images = try JSONDecoder().decode([String].self, from: Data(imagesLinks.description.utf8))
                    for image in images {
                        if let imageUrl = URL(string: image) {
                            DispatchQueue.main.async {
                                self.images.append(imageUrl)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        completion?()
                    }
                } catch { }
            }
        }.resume()
    }
    
    func getStruct() -> Volume {
        return Volume(name: self.name, link: self.link, images: self.images, downloadedImages: self.downloadedImages, downloaded: self.downloaded)
    }
}

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
    
    init() {
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

