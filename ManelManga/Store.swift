//
//  Store.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import Foundation

struct Manga: Hashable, Codable {
    let name: String
    let image: String
    let link: String
    let actualVolume: Int
}

struct Anime: Codable, Hashable {
    let name: String
    var image: String
    let link: String
    var lastEpisode: Int
    var episodes: [Episode]
}

struct Episode: Codable, Hashable {
    let name: String
    let thumb: String
    let videoLink: String
    var visualized: Bool
}

struct Source: Codable, Hashable {
    let file: String
    let type: String
    let label: String
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
