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
}

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
