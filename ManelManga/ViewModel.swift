//
//  ViewModel.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import Foundation


struct Manga: Hashable {
    let name: String
    let image: String
    let link: String
    let actualVolume: Int
}

class ViewModel: ObservableObject {
    @Published var link: String = ""
    
    @Published var page: Pages = .Home
    
    @Published var mangas = [
        Manga(
            name: "Pick Me Up!",
            image: "https://i0.wp.com/imperioscans.com.br/wp-content/uploads/2023/09/Pick_me_up_-_Piccoma.jpg?fit=193%2C273&ssl=1",
            link: "https://imperioscans.com.br/manga/pick-me-up/",
            actualVolume: 1
        ),
        Manga(
            name: "The Mad Gate",
            image: "https://i0.wp.com/imperioscans.com.br/wp-content/uploads/2023/09/TMG_poster_full_res.webp?fit=180%2C278&ssl=1",
            link: "https://imperioscans.com.br/manga/the-mad-gate/",
            actualVolume: 1
        )
    ]
    
    @Published var manga: Manga? = nil
}
