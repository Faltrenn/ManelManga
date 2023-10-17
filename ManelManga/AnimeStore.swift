//
//  AnimeStore.swift
//  ManelManga
//
//  Created by Emanuel on 16/10/23.
//

import Foundation

enum VideoQuality: CaseIterable {
    case SD, HD, FHD
    static func getQuality(source: Source) -> VideoQuality? {
        let type = source.label.split(separator: " ")[0]
        switch type {
        case "SD":
            return .SD
        case "HD":
            return .HD
        case "FHD":
            return .FHD
        default:
            return nil
        }
    }
}

struct Source: Codable, Hashable {
    var file: String
    var type: String
    var label: String
}

struct DownloadedVideo: Codable, Hashable {
    var SD: String? = nil
    var HD: String? = nil
    var FHD: String? = nil
    
    mutating func set(source: Source, url: URL) {
        if let quality = VideoQuality.getQuality(source: source) {
            switch quality {
            case .SD:
                SD = url.absoluteString
            case .HD:
                HD = url.absoluteString
            case .FHD:
                FHD = url.absoluteString
            }
        }
        //MARK: Testar
    }
    
    mutating func reset(quality: VideoQuality) {
        switch quality {
        case .SD:
            SD = nil
        case .HD:
            HD = nil
        case .FHD:
            FHD = nil
        }
        //MARK: Testar
    }
    
    func get(quality: VideoQuality? = nil) -> String? {
        if let quality = quality {
            switch quality {
            case .SD:
                return SD
            case .HD:
                return HD
            case .FHD:
                return FHD
            }
        } else {
            return FHD ?? HD ?? SD ?? nil
        }
    }
}

struct Episode: Codable, Hashable {
    var name: String
    var thumb: String
    var videoLink: String
    var downloads: DownloadedVideo = DownloadedVideo()
    var visualized: Bool = false
    
    func getClass() -> EpisodeClass {
        return EpisodeClass(episode: self)
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

struct Anime: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var episodes: [Episode]
    
    func getClass() -> AnimeClass {
        return AnimeClass(anime: self)
    }
}

class AnimeClass: ObservableObject, Hashable {
    static func == (lhs: AnimeClass, rhs: AnimeClass) -> Bool {
        return lhs.name == rhs.name && lhs.link == rhs.link
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.link)
    }
    
    var name: String
    var image: String
    var link: String
    @Published var episodes: [EpisodeClass]
    
    init(anime: Anime) {
        self.name = anime.name
        self.image = anime.image
        self.link = anime.link
        self.episodes = []
        for episode in anime.episodes {
            self.episodes.append(episode.getClass())
        }
    }
    
    func getStruct() -> Anime {
        var episodes: [Episode] = []
        for episode in self.episodes {
            episodes.append(Episode(name: episode.name, thumb: episode.thumb, videoLink: episode.videoLink, visualized: episode.visualized))
        }
        return Anime(name: self.name, image: self.image, link: self.link, episodes: episodes)
    }
}
