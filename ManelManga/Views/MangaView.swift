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
    
    @State var volumes: [String] = []
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Button(action: {
                    mainViewModel.page = .Home
                }, label: {
                  Text("Voltar")
                        .font(.title2)
                })
                Spacer()
            }
            .padding()
            .zIndex(1)
            ScrollView {
                VStack {
                    if let manga = mainViewModel.manga {
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
                    ForEach(volumes, id: \.self) { volume in
                        Button {
                            mainViewModel.link = volume
                            mainViewModel.page = .Volume
                        } label: {
                            Text("Volume: \(volumes.count - volumes.firstIndex(of: volume)!)")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                .onAppear {
                    if let manga = mainViewModel.manga {
                        guard let url = URL(string: manga.link) else {
                            return
                        }
                        URLSession.shared.dataTask(with: url) { data, _, error in
                            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                                do {
                                    let doc = try SwiftSoup.parse(html)
                                    let elements = try doc.select("li[class=wp-manga-chapter] a").array()
                                    var vs: [String] = []
                                    for volume in elements {
                                        vs.append(try volume.attr("href"))
                                    }
                                    volumes = vs
                                } catch {
                                    print(error)
                                }
                            }
                        }.resume()
                    }
                }
            }
        }
    }
}

struct MangaView_Previews: PreviewProvider {
    static var previews: some View {
        MangaView()
            .environmentObject(MainViewModel())
    }
}
