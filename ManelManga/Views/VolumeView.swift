//
//  VolumeView.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import SwiftUI
import SwiftSoup

struct VolumeView: View {
    let link: String
    @State var images: [String] = []
        
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(images, id: \.self) { image in
                            AsyncImage(url: URL(string: image)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
            }
            .onAppear {
                getVolume()
            }
        }
    }
    
    func getVolume() {
        guard let url = URL(string: link) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                let html = String(data: data, encoding: .utf8)
                if let html = html {
                    do {
                        let doc = try SwiftSoup.parse(html)
                        let imgs = try doc.select("img[class=wp-manga-chapter-img]")
                        var imagesList: [String] = []
                        for img in imgs.array() {
                            let link = try img.attr("src")
                            imagesList.append(String(link.suffix(link.count-7)))
                        }
                        DispatchQueue.main.async {
                            images = imagesList
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }.resume()
    }
}

struct VolumeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
