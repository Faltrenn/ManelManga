//
//  AnimeHomeView.swift
//  ManelManga
//
//  Created by Emanuel on 22/09/23.
//

import SwiftUI
import SwiftSoup
import AVKit

struct AnimeHomeView: View {
    @State var animeLink = ""
    @State var link = ""
    @State var play = false
    @State var sources: [Source] = []
    @State var player = AVPlayer()
    @State var videoLink = ""
    
    @State var animes: [Anime] = []
    
    @State var isPresented = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                }
                .zIndex(1)
                .padding(.horizontal)
                ScrollView {
                    VStack {
                        ForEach(animes, id: \.self) { anime in
                            NavigationLink {
                                AnimeView(anime: anime)
                            } label: {
                                AnimeCard(anime: anime, animes: $animes)
                            }
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                }
            }
        }
        .alert("Adicionar anime", isPresented: $isPresented) {
            AddAnime(animes: $animes)
        }
        .onAppear {
            guard let data = UserDefaults.standard.data(forKey: "animes") else {
                return
            }
            do {
                animes = try JSONDecoder().decode([Anime].self, from: data)
            } catch { }
        }
    }
}

struct AddAnime: View {
    @State var linkAnime = ""
    @Binding var animes: [Anime]
    
    var body: some View {
        TextField("Link do anime", text: $linkAnime)
        Button("Adicionar") {
            addManga()
        }
        Button("Cancelar", role: .cancel) { }
    }
    
    func addManga() {
        guard let url = URL(string: linkAnime) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let doc = try SwiftSoup.parse(html)
                    
                    let name = try doc.select("h2[class=film-name dynamic-name]").text()
                    
                    let image = try doc.select("div[class=anisc-poster] div img").attr("src")
                    
                    print(image)
                    
                    animes.append(Anime(name: name, image: image, link: linkAnime, lastEpisode: 1, episodes: []))
                    UserDefaults.standard.setValue(try JSONEncoder().encode(self.animes), forKey: "animes")
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
}

struct AnimeCard: View {
    let anime: Anime
    @Binding var animes: [Anime]
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: anime.image)) { image in
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
                Text(anime.name)
                    .font(.title2)
                    .lineLimit(3)
                    .bold()
                    .frame(maxWidth: .infinity)
                Text("Episódio atual: \(anime.lastEpisode)")
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        animes.removeAll { anm in
                            anm == anime
                        }
                        do {
                            UserDefaults.standard.setValue(try JSONEncoder().encode(self.animes), forKey: "animes")
                        } catch { }
                    } label: {
                        Circle()
                            .fill(.red)
                            .frame(width: 40)
                            .overlay {
                                Text("X")
                            }
                    }
                }
                .padding()
                
            }
            .font(.title3)
        }
        .background(.gray)
        .foregroundColor(.white)
    }
}

struct AnimeHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeHomeView()
    }
}
