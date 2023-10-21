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
    
    @State var volumeID: Int
    
    @State var images: [URL] = []
    
    @State var tabBarVisibility = false
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(images, id: \.self) { img in
                        AsyncImage(url: img) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    if volumeID + 1 < manga.volumes.count {
                        Button {
                            volumeID += 1
                            getImages(volume: manga.volumes[volumeID])
                        } label: {
                            Text("Next")
                                .font(.title)
                        }.padding(.bottom)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(tabBarVisibility)
        .navigationBarBackButtonHidden(tabBarVisibility)
        .animation(.easeIn, value: tabBarVisibility)
        .onTapGesture {
            tabBarVisibility.toggle()
        }
        .onAppear {
            getImages(volume: manga.volumes[volumeID])
        }
    }
    
    func getImages(volume: VolumeClass) {
        if !volume.downloaded {
            volume.getImages { imagesURLs in
                images = imagesURLs
            }
        } else {
            images = volume.getDownloadedImagesURLs(manga: manga) ?? []
        }
    }
}

//extension UINavigationController: UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return viewControllers.count > 1
//    }
//}

#Preview {
    VolumeView(manga: MainViewModel.shared.mangas[1], volumeID: 0)
        .environmentObject(MainViewModel.shared)
}
