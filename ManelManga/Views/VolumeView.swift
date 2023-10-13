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
                    if volume.downloadedImages.count > 0 {
                        ForEach(volume.downloadedImages, id: \.self) { image in
                            AsyncImage(url: getImageURL(manga: manga, volume: volume, image: image)) { img in
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
            if self.volume.downloadedImages.count == 0 {
                self.volume.getImages {
                    mainViewModel.saveMangas()
                }
            }
        }
    }
}

struct VolumeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
