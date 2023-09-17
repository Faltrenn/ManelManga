//
//  HomeView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct HomeView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var isPresented = false

    var body: some View {
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
                    ForEach(mainViewModel.mangas, id: \.self) { mng in
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
                mainViewModel.mangas = try JSONDecoder().decode([Manga].self, from: data)
            } catch { }
        }    }
}

struct AddManga: View {
    @EnvironmentObject var mainViewModel: MainViewModel
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
                        
                        mainViewModel.mangas.append(Manga(name: name, image: image, link: linkManga, actualVolume: 1))
                        UserDefaults.standard.setValue(try JSONEncoder().encode(mainViewModel.mangas), forKey: "mangas")
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
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        Button(action: {
            mainViewModel.manga = manga
            mainViewModel.page = .Manga
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
