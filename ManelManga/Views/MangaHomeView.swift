//
//  HomeView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct MangaHomeView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var isPresented: Bool = false
    
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
            .zIndex(1)
            .padding(.horizontal)
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(mainViewModel.mangas, id: \.self) { manga in
                        NavigationLink {
                            MangaView(manga: manga)
                        } label: {
                            MangaCard(manga: manga)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
            }
        }
        .alert("Adicionar manga", isPresented: $isPresented) {
            AddManga()
        }
    }
}

struct AddManga: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var mangaLink = "" //"https://www.brmangas.net/manga/is-this-hero-for-real-online/"
    
    var body: some View {
        TextField("Link do mangá", text: $mangaLink)
        Button("Adicionar") {
            mainViewModel.addManga(mangaLink: mangaLink)
            mangaLink = ""
        }
        Button("Cancelar", role: .cancel) { }
    }
}

struct MangaCard: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @ObservedObject var manga: MangaClass
    
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
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        mainViewModel.removeManga(manga: manga)
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

#Preview{
    return ContentView()
        .environmentObject(MainViewModel.shared)
}
