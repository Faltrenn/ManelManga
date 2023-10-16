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
                            VolumeView(manga: manga, volume: volume)
                        } label: {
                            VolumeCard(manga: manga, volume: volume)
                        }
                    }
                }
            }
        }
    }
}

struct VolumeCard: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @ObservedObject var manga: MangaClass
    @ObservedObject var volume: VolumeClass
    @ObservedObject var session = MangaURLSession()
    
    var body: some View {
        HStack {
            Text(volume.name)
                .font(.title3)
                .bold()
            if !volume.downloaded {
                Button {
                    session.downloadVolume(manga: manga, volume: volume, mainViewModel: mainViewModel)
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .font(.title2)
                        .bold()
                        .padding(6)
                        .overlay {
                            if session.downloadTask != nil {
                                Circle()
                                    .stroke(.gray, style: StrokeStyle(lineWidth: 3))
                                Circle()
                                    .trim(from: 0, to: session.progress)
                                    .stroke(.blue, style: StrokeStyle(lineWidth: 3))
                                    .rotationEffect(Angle(degrees: -90))
                            }
                        }
                        .animation(.easeIn, value: session.progress)
                }
            } else {
                Button {
                    manga.deleteVolume(volume: volume)
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let mainViewModel = MainViewModel()
    return MangaView(manga: mainViewModel.mangas.first!)
        .environmentObject(mainViewModel)
}
