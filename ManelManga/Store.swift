//
//  Store.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import Foundation

enum Pages {
    case Home, Manga, Volume
}

struct Manga: Hashable, Codable {
    let name: String
    let image: String
    let link: String
    let actualVolume: Int
}
