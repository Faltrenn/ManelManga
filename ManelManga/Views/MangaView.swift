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
                            VolumeCard(manga: manga, volume: volume)
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
                            volumes.append(Volume(name: try volume.text(), link: try volume.attr("href"), images: [], downloadedImages: []).getClass())
                        }
                        if volumes != manga.volumes {
                            for volume in manga.volumes {
                                if let vol = volumes.first(where: { $0 == volume }) {
                                    vol.images = volume.images
                                    vol.downloadedImages = volume.downloadedImages
                                }
                            }
                            
                            manga.volumes = volumes
                            mainViewModel.saveMangas()
                        }
                    } catch {
                        print(error)
                    }
                }
            }.resume()
        }
    }
}

struct VolumeCard: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @ObservedObject var manga: MangaClass
    @ObservedObject var volume: VolumeClass
    @ObservedObject var session = CustomURLSession()
    
    var body: some View {
        HStack {
            Text(volume.name)
                .font(.title3)
                .bold()
            Button {
                session.downloadVolume(manga: manga, volume: volume) { _ in
                    mainViewModel.saveMangas()
                }
            } label: {
                Image(systemName: "arrow.down.to.line")
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    func getImages() {
        if volume.images.count == 0 {
            guard let url = URL(string: volume.link) else {
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                    do {
                        let imagesLinks = html.split(separator: "\\\"images\\\": ")[1].split(separator: "}")[0].replacing("\\", with: "")
                        let images = try JSONDecoder().decode([String].self, from: Data(imagesLinks.description.utf8))
                        for image in images {
                            if let imageUrl = URL(string: image) {
                                volume.images.append(imageUrl)
                            }
                        }
                        mainViewModel.saveMangas()
                    } catch { }
                }
            }.resume()
        }
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
