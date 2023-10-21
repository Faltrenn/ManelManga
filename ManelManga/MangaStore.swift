//
//  MangaStore.swift
//  ManelManga
//
//  Created by Emanuel on 16/10/23.
//

import Foundation

struct Manga: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var volumes: [Volume]
    
    func getClass() -> MangaClass {
        return MangaClass(manga: self)
    }
}

class MangaClass: ObservableObject, Hashable {
    static func == (lhs: MangaClass, rhs: MangaClass) -> Bool {
        return lhs.getStruct() == rhs.getStruct()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    
    var name: String
    var image: String
    var link: String
    @Published var volumes: [VolumeClass]
    
    init(manga: Manga) {
        self.name = manga.name
        self.image = manga.image
        self.link = manga.link
        self.volumes = []
        for volume in manga.volumes {
            volumes.append(volume.getClass())
        }
    }
    
    func getStruct() -> Manga {
        var volumes: [Volume] = []
        for volume in self.volumes {
            volumes.append(volume.getStruct())
        }
        return Manga(name: self.name, image: self.image, link: self.link, volumes: volumes)
    }
    
    func deleteVolume(volume: VolumeClass) {
        if volume.downloaded {
            do {
                try FileManager.default.removeItem(at: volume.getDirectory(manga: self))
            } catch { }
            
            volume.downloadedImages = []
            volume.downloaded = false
            
            MainViewModel.shared.saveMangas()
        }
    }
    
    func getDirectory() -> URL {
        getMangasDirectory().appendingPathComponent(self.name, isDirectory: true)
    }
    
    func getNextVolume(volume: VolumeClass) -> VolumeClass? {
        if let id = self.volumes.firstIndex(of: volume), self.volumes.count > (id+1) {
            return self.volumes[id+1]
        }
        return nil
    }
}

struct Volume: Codable, Hashable{
    var name: String
    var link: String
    var downloadedImages: [String]
    var downloaded: Bool
    
    func getClass() -> VolumeClass {
        return VolumeClass(volume: self)
    }
}

class VolumeClass: ObservableObject, Hashable {
    static func == (lhs: VolumeClass, rhs: VolumeClass) -> Bool {
        return lhs.name == rhs.name && lhs.link == rhs.link
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    
    var name: String
    var link: String
    @Published var downloadedImages: [String]
    @Published var downloaded: Bool
    
    init(volume: Volume) {
        self.name = volume.name
        self.link = volume.link
        self.downloadedImages = volume.downloadedImages
        self.downloaded = volume.downloaded
    }
    
    func getDownloadedImagesURLs(manga: MangaClass) -> [URL]? {
        var urls: [URL] = []
        for image in self.downloadedImages {
            let path = self.getDirectory(manga: manga)
                .appendingPathComponent(image)
            if FileManager.default.fileExists(atPath: path.path(percentEncoded: false)) {
                urls.append(path)
            }
        }
        return urls.count > 0 ? urls : nil
    }
    
    func getImages(completion: (([URL]) -> Void)? = nil) {
        guard let url = URL(string: link) else { return }
        var imagesURLs: [URL] = []
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let imagesLinks = html.split(separator: "\\\"images\\\": ")[1].split(separator: "}")[0].replacing("\\", with: "")
                    let images = try JSONDecoder().decode([String].self, from: Data(imagesLinks.description.utf8))
                    for image in images {
                        if let imageUrl = URL(string: image) {
                            imagesURLs.append(imageUrl)
                        }
                    }
                    DispatchQueue.main.async {
                        completion?(imagesURLs)
                    }
                } catch { }
            }
        }.resume()
    }
    
    func getStruct() -> Volume {
        Volume(name: self.name, link: self.link, downloadedImages: self.downloadedImages, downloaded: self.downloaded)
    }
    
    func getDirectory(manga: MangaClass) -> URL {
        manga.getDirectory().appendingPathComponent(self.name, isDirectory: true)
    }
}

struct DownloadElement {
    let url: URL
    let saveAt: URL
    var volume: VolumeClass
}
