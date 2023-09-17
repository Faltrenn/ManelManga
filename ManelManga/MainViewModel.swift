//
//  ViewModel.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import Foundation


struct Manga: Hashable, Codable {
    let name: String
    let image: String
    let link: String
    let actualVolume: Int
}

class MainViewModel: ObservableObject {
    @Published var link: String
    
    @Published var page: Pages
    
    @Published var mangas: [Manga]
    
    @Published var manga: Manga?
    
    init(link: String = "", page: Pages = .Home, mangas: [Manga] = [], manga: Manga? = nil) {
        self.link = link
        self.page = page
        self.mangas = mangas
        self.manga = manga
    }
}
