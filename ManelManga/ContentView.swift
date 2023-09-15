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
    @EnvironmentObject var viewModel: ViewModel
    
    @State var isPresented = false
    
    var body: some View {
        ZStack {
            switch viewModel.page {
            case .Home:
                ZStack(alignment: .topTrailing) {
                    Button {
                        isPresented.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50)
                    }
                    .padding(.trailing)
                    .zIndex(1)

                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.mangas, id: \.self) { mng in
                                MangaCard(manga: mng)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 60)
                    }
                }
                .alert("Adicionar anime", isPresented: $isPresented) {
                    AddManga()
                }
                .onAppear {
                    guard let data = UserDefaults.standard.data(forKey: "mangas") else {
                        return
                    }
                    do {
                        viewModel.mangas = try JSONDecoder().decode([Manga].self, from: data)
                    } catch { }
                }
            case .Manga:
                MangaView()
            case .Volume:
                VolumeView()
            }
        }
    }
}

struct AddManga: View {
    @EnvironmentObject var viewModel: ViewModel
    @State var linkManga = ""
    
    var body: some View {
        TextField("Link do mangá", text: $linkManga)
            .foregroundColor(.black)
        Button("Adicionar") {
            guard let url = URL(string: linkManga) else {
                return
            }
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                    do {
                        let doc = try SwiftSoup.parse(html)
                        
                        let name = try doc.select("div[class=post-title] h1").text()
                        
                        let image = try doc.select("div[class=summary_image] a img").attr("src")
                        
                        viewModel.mangas.append(Manga(name: name, image: image, link: linkManga, actualVolume: 1))
                        UserDefaults.standard.setValue(try JSONEncoder().encode(viewModel.mangas), forKey: "mangas")
                    } catch {
                        print(error)
                    }
                }
            }.resume()
            
        }
        Button("Cancelar", role: .cancel) { }
    }
}


struct MangaCard: View {
    let manga: Manga
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        Button(action: {
            viewModel.manga = manga
            viewModel.page = .Manga
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
    @EnvironmentObject var viewModel: ViewModel
    
    @State var volumes: [String] = []
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Button(action: {
                    viewModel.page = .Home
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
                    if let manga = viewModel.manga {
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
                            viewModel.link = volume
                            viewModel.page = .Volume
                        } label: {
                            Text("Volume: \(volumes.count - volumes.firstIndex(of: volume)!)")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                .onAppear {
                    if let manga = viewModel.manga {
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
    @EnvironmentObject var viewModel: ViewModel
    
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
                    viewModel.page = .Manga
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
                guard let url = URL(string: viewModel.link) else {
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
            .environmentObject(ViewModel())
    }
}
