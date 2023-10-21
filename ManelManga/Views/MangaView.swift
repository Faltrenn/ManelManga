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
                    ForEach(0 ..< manga.volumes.count, id: \.self) { id in
                        NavigationLink {
                            VolumeView(manga: manga, volumeID: id)
                        } label: {
                            VolumeCard(manga: manga, volume: manga.volumes[id])
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
    
    @State var downloading: Bool = false
    @State var progress: CGFloat = .zero
    
    
    var body: some View {
        HStack {
            Text(volume.name)
                .font(.title3)
                .bold()
            if !volume.downloaded {
                Button {
                    MangaURLSession.shared.addVolumeToQueue(manga: manga, volume: volume, downloading: $downloading, progress: $progress)
                    downloading = true
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .font(.title2)
                        .bold()
                        .padding(6)
                        .overlay {
                            if downloading {
                                Circle()
                                    .stroke(.gray, style: StrokeStyle(lineWidth: 3))
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(.blue, style: StrokeStyle(lineWidth: 3))
                                    .rotationEffect(Angle(degrees: -90))
                            }
                        }
                        .animation(.easeIn, value: progress)
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
    MangaView(manga: MainViewModel.shared.mangas.first!)
        .environmentObject(MainViewModel.shared)
}
