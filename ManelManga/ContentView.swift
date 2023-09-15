//
//  ContentView.swift
//  ManelManga
//
//  Created by Emanuel on 15/09/23.
//

import SwiftUI
import SwiftSoup

enum Pages {
    case Home, Manga, Volume
}

struct ContentView: View {
    @State var link: String = ""
    
    @State var page: Pages = .Home
    
    @State var mangas = [
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
    
    @State var manga: Manga? = nil
    
    var body: some View {
        ZStack {
            switch page {
            case .Home:
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(mangas, id: \.self) { mng in
                            MangaCard(manga: mng, page: $page, mangaLink: $manga)
                        }
                    }
                    .padding()
                }
            case .Manga:
                MangaView(manga: $manga, link: $link, page: $page)
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
    @Binding var mangaLink: Manga?
    
    var body: some View {
        Button(action: {
            mangaLink = manga
            page = .Manga
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

struct MangaView: View {
    @Binding var manga: Manga?
    @Binding var link: String
    @Binding var page: Pages
    @State var volumes: [String] = []
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
            ScrollView {
                VStack {
                    if let manga = manga {
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
                    }
                    ForEach(volumes, id: \.self) { volume in
                        Button {
                            link = volume
                            page = .Volume
                        } label: {
                            Text(volume)
                                .font(.title3)
                                .bold()
                        }
                        
                    }
                }
                .onAppear {
                    if let manga = manga {
                        guard let url = URL(string: manga.link) else {
                            return
                        }
                        URLSession.shared.dataTask(with: url) { data, _, error in
                            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                                do {
                                    let doc = try SwiftSoup.parse(html)
                                    let elements = try doc.select("li[class=wp-manga-chapter] a").array()
                                    var vs: [String] = []
                                    for volume in elements {
                                        vs.append(try volume.attr("href"))
                                    }
                                    volumes = vs
                                } catch {
                                    print(error)
                                }
                            }
                        }.resume()
                    }
                }
            }
        }
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
                    page = .Manga
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
