//
//  Store.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import Foundation

struct Manga: Hashable, Codable {
    var name: String
    var image: String
    var link: String
}

struct Anime: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var episodes: [Episode]
}

struct Episode: Codable, Hashable {
    var name: String
    var thumb: String
    var videoLink: String
    var downloadedVideoPath: String?
    var visualized: Bool
}

struct Source: Codable, Hashable {
    var file: String
    var type: String
    var label: String
}

enum Pages: CaseIterable {
    case Anime, Manga
    
    var unsIcon: String {
        switch self {
        case .Anime:
            return "play.circle"
        case .Manga:
            return "book"
        }
    }
    var selIcon: String {
        switch self {
        case .Anime:
            return "play.circle.fill"
        case .Manga:
            return "book.fill"
        }
    }
    var title: String {
        switch self {
        case .Anime:
            return "Anime"
        case .Manga:
            return "Mangá"
        }
    }
}
