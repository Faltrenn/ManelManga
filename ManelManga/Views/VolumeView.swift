//
//  VolumeView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct VolumeView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    var manga: MangaClass
    @ObservedObject var volume: VolumeClass
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    if volume.downloaded {
                        ForEach(volume.getDownloadedImagesURLs(manga: manga)!, id: \.self) { image in
                            AsyncImage(url: image) { img in
                                img
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    } else {
                        ForEach(volume.images, id: \.self) { image in
                            AsyncImage(url: image) { img in
                                img
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if !self.volume.downloaded {
                self.volume.getImages()
            }
        }
    }
}

#Preview {
    return ContentView()
        .environmentObject(MainViewModel.shared)
}
