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
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    
    let maxZoom = 5.0
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
//        .scaleEffect(currentZoom + totalZoom)
//        .gesture(
//            MagnificationGesture()
//                .onChanged { value in
//                    let newValue = currentZoom + totalZoom + value.magnitude - 1
//                    if newValue > 1 {
//                        currentZoom = value.magnitude - 1
//                    }
//                }
//                .onEnded { value in
//                    totalZoom += currentZoom
//                    currentZoom = 0
//                }
//        )
//        .gesture(TapGesture(count: 2)
//            .onEnded({ _ in
//                totalZoom = 1
//            })
//        )
    }
}

struct VolumeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
