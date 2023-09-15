//
//  ContentView.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI
import SwiftSoup

enum Pages {
    case Home, Volume
}

struct ContentView: View {
    @State var link = "" // Link do volume
    
    @State var page: Pages = .Home
    
    @State var mangas = [
        Manga(
            name: "Pick Me Up!",
            image: "https://i0.wp.com/imperioscans.com.br/wp-content/uploads/2023/09/Pick_me_up_-_Piccoma.jpg?fit=193%2C273&ssl=1",
            link: "https://imperioscans.com.br/manga/pick-me-up/01/",
            actualVolume: 1
        ),
        Manga(
            name: "The Mad Gate",
            image: "https://i0.wp.com/imperioscans.com.br/wp-content/uploads/2023/09/TMG_poster_full_res.webp?fit=180%2C278&ssl=1",
            link: "https://imperioscans.com.br/manga/the-mad-gate/01/",
            actualVolume: 1
        )
    ]
    
    var body: some View {
        ZStack {
            switch page {
            case .Home:
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(mangas, id: \.self) { manga in
                            MangaCard(manga: manga, page: $page, link: $link)
                        }
                    }
                    .padding()
                }
            case .Volume:
                VolumeView(link: link, page: $page)
            }
        }
    }
}

struct Manga: Hashable {
    let name: String
    let image: String
    let link: String
    let actualVolume: Int
    
}

struct MangaCard: View {
    let manga: Manga
    @Binding var page: Pages
    @Binding var link: String
    
    var body: some View {
        Button(action: {
            link = manga.link
            page = .Volume
        }, label: {
            HStack {
                AsyncImage(url: URL(string: manga.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                } placeholder: {
                    Rectangle()
                        .frame(width: 150, height: 150)
                        .overlay {
                            ProgressView()
                        }
                }
                VStack(alignment: .leading) {
                    Text(manga.name)
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity)
                    Text("Volume atual: \(manga.actualVolume)")
                    Spacer()
                }
                .font(.title3)
            }
            .background(.gray)
        })
        .foregroundColor(.white)
    }
}

struct VolumeView: View {
    let link: String
    @Binding var page: Pages
    
    @State var images: [String] = []
    
    func getVolume(url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                let html = String(data: data, encoding: .utf8)
                if let html = html {
                    do {
                        let doc = try SwiftSoup.parse(html)
                        let imgs = try doc.select("img[class=wp-manga-chapter-img]")
                        var imagesList: [String] = []
                        for img in imgs.array() {
                            let link = try img.attr("src")
                            imagesList.append(String(link.suffix(link.count-7)))
                        }
                        images = imagesList
                    } catch {
                        print(error)
                    }
                }
            }
        }.resume()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Button(action: {
                    page = .Home
                }, label: {
                  Text("Voltar")
                        .font(.title2)
                })
                Spacer()
            }
            .padding()
            .zIndex(1)
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(images, id: \.self) { image in
                            AsyncImage(url: URL(string: image)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
            }
            .onAppear {
                guard let url = URL(string: link) else {
                    return
                }
                getVolume(url: url)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
