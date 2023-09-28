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
    @ObservedObject var volume: VolumeClass
    
//    @State private var currentZoom = 0.0
//    @State private var totalZoom = 1.0
    
    let maxZoom = 5.0
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if volume.downloadedImages.count > 0 {
                    ForEach(volume.downloadedImages, id:\.self) { downloadedImage in
                        AsyncImage(url: downloadedImage) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                } else if volume.images.count > 0 {
                    ForEach(volume.images, id:\.self) { image in
                        AsyncImage(url: image) { img in
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                } else {
                    ProgressView()
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
        .onAppear {
            getImages()
        }
    }
        
    func getImages() {
        if volume.images.count == 0 {
            guard let url = URL(string: volume.link) else {
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                    do {
                        let imagesLinks = html.split(separator: "\\\"images\\\": ")[1].split(separator: "}")[0].replacing("\\", with: "")
                        let images = try JSONDecoder().decode([String].self, from: Data(imagesLinks.description.utf8))
                        for image in images {
                            if let imageUrl = URL(string: image) {
                                volume.images.append(imageUrl)
                            }
                        }
                        mainViewModel.saveMangas()
                    } catch { }
                }
            }.resume()
        }
    }
}

struct VolumeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
