//
//  HomeView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct MangaHomeView: View {
    @State var isPresented = false
    @State var mangas: [Manga] = []

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
                    VStack(alignment: .leading) {
                        ForEach(mangas, id: \.self) { manga in
                            NavigationLink {
                                MangaView(manga: manga)
                            } label: {
                                MangaCard(manga: manga, mangas: $mangas)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                }
            }
        }
        .alert("Adicionar manga", isPresented: $isPresented) {
            AddManga(mangas: $mangas)
        }
        .onAppear {
            guard let data = UserDefaults.standard.data(forKey: "mangas") else {
                return
            }
            do {
                mangas = try JSONDecoder().decode([Manga].self, from: data)
            } catch { }
        }
    }
}


struct AddManga: View {
    @State var linkManga = ""
    @Binding var mangas: [Manga]
    
    var body: some View {
        TextField("Link do mangá", text: $linkManga)
        Button("Adicionar") {
            addManga()
        }
        Button("Cancelar", role: .cancel) { }
    }
    
    func addManga() {
        guard let url = URL(string: linkManga) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let doc = try SwiftSoup.parse(html)
                    
                    let name = try doc.select("div[class=post-title] h1").text()
                    
                    let image = try doc.select("div[class=summary_image] a img").attr("src")
                    
                    mangas.append(Manga(name: name, image: image, link: linkManga, actualVolume: 1))
                    UserDefaults.standard.setValue(try JSONEncoder().encode(self.mangas), forKey: "mangas")
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
}

struct MangaCard: View {
    let manga: Manga
    @Binding var mangas: [Manga]
    
    var body: some View {
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
                HStack {
                    Spacer()
                    Button {
                        mangas.removeAll { mng in
                            mng == manga
                        }
                        do {
                            UserDefaults.standard.setValue(try JSONEncoder().encode(self.mangas), forKey: "mangas")
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
