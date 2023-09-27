//
//  MangaView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct MangaView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @ObservedObject var manga: MangaClass
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack {
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
                    ForEach(manga.volumes, id: \.self) { volume in
                        NavigationLink {
                            VolumeView(volume: volume)
                        } label: {
                            Text(volume.name)
                                .font(.title3)
                                .bold()
                        }
                    }
                }
            }
        }
        .onAppear {
            guard let url = URL(string: manga.link) else {
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                    do {
                        let doc = try SwiftSoup.parse(html)
                        
                        let volumesElements = try doc.select("li[class=row lista_ep] a").array()
                        
                        var volumes: [VolumeClass] = []
                        for volume in volumesElements {
                            volumes.append(Volume(name: try volume.text(), link: try volume.attr("href"), images: nil, downloadedImages: nil).getClass())
                        }
                        if volumes != manga.volumes {
                            for volume in manga.volumes {
                                if let vol = volumes.first(where: { $0 == volume }) {
                                    vol.images = volume.images
                                    vol.downloadedImages = volume.downloadedImages
                                }
                            }
                            
                            manga.volumes = volumes
//                            mainViewModel.saveMangas()
                        }
                    } catch {
                        print(error)
                    }
                }
            }.resume()
        }
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(manga: MainViewModel().mangas.first ?? Manga(name: "Manga", image: "https://viralcontentmxp.xyz/uploads/u/underworld-restaurant/underworld-restaurant.jpg", link: "https://www.brmangas.net/manga/underworld-restaurant-online/", volumes: [Volume(name: "Volume 3", link: "https://www.brmangas.net/ler/underworld-restaurant-3-online/")]).getClass())
    }
}
