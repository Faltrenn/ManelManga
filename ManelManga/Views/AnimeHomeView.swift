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
    @EnvironmentObject var mainViewModel: MainViewModel
    
    @State var animeLink = ""
    @State var link = ""
    @State var play = false
    @State var sources: [Source] = []
    @State var player = AVPlayer()
    @State var videoLink = ""
    
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
                        ForEach(mainViewModel.animes, id: \.self) { anime in
                            NavigationLink {
                                AnimeView(anime: anime)
                            } label: {
                                AnimeCard(anime: anime)
                            }
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                }
            }
        }
        .alert("Adicionar anime", isPresented: $isPresented) {
            AddAnime()
        }
    }
}

struct AddAnime: View {
    @State var animelink = "https://animes.vision/animes/mieruko-chan-dublado"
    
    var body: some View {
        TextField("Link do anime", text: $animelink)
            .textInputAutocapitalization(.never)
            .textCase(.none)
            .autocorrectionDisabled()
        Button("Adicionar") {
            MainViewModel.shared.addAnime(animelink: animelink)
            animelink = ""
        }
        Button("Cancelar", role: .cancel) { }
    }
}

struct AnimeCard: View {
    let anime: AnimeClass
    
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
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        MainViewModel.shared.removeAnime(anime: anime)
                        MainViewModel.shared.saveAnimes()
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

#Preview {
    ContentView()
        .environmentObject(MainViewModel.shared)
}
