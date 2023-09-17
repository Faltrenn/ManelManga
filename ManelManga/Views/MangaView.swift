//
//  MangaView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct MangaView: View {
    let manga: Manga
    @State var volumes: [String] = []
    
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
                    ForEach(volumes, id: \.self) { volume in
                        NavigationLink {
                            VolumeView(link: volume)
                        } label: {
                            Text("Volume: \(volumes.count - volumes.firstIndex(of: volume)!)")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                .onAppear {
                    getVolumes(link: manga.link)
                }
            }
        }
    }
    
    func getVolumes(link: String) {
        guard let url = URL(string: link) else {
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
                    DispatchQueue.main.async {
                        volumes = vs
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView(manga: Manga(name: "Name", image: "Image", link: "Link", actualVolume: 1))
    }
}
