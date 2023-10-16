//
//  Store.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import Foundation

func getMangasDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Mangas", isDirectory: true)
}

struct Anime: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var episodes: [Episode]
}

struct Episode: Codable, Hashable {
    var name: String
    var thumb: String
    var videoLink: String
    var downloads: DownloadedVideo = DownloadedVideo()
    var visualized: Bool = false
}

enum VideoQuality: CaseIterable {
    case SD, HD, FHD
    static func getQuality(source: Source) -> VideoQuality? {
        let type = source.label.split(separator: " ")[0]
        switch type {
        case "SD":
            return .SD
        case "HD":
            return .HD
        case "FHD":
            return .FHD
        default:
            return nil
        }
    }
}

struct DownloadedVideo: Codable, Hashable {
    var SD: String? = nil
    var HD: String? = nil
    var FHD: String? = nil
    
    mutating func set(source: Source, url: URL) {
        if let quality = VideoQuality.getQuality(source: source) {
            switch quality {
            case .SD:
                SD = url.absoluteString
            case .HD:
                HD = url.absoluteString
            case .FHD:
                FHD = url.absoluteString
            }
        }
        //MARK: Testar
    }
    
    mutating func reset(quality: VideoQuality) {
        switch quality {
        case .SD:
            SD = nil
        case .HD:
            HD = nil
        case .FHD:
            FHD = nil
        }
        //MARK: Testar
    }
    
    func get(quality: VideoQuality? = nil) -> String? {
        if let quality = quality {
            switch quality {
            case .SD:
                return SD
            case .HD:
                return HD
            case .FHD:
                return FHD
            }
        } else {
            return FHD ?? HD ?? SD ?? nil
        }
    }
}

struct Source: Codable, Hashable {
    var file: String
    var type: String
    var label: String
}

class AnimeClass: ObservableObject {
    var name: String
    var image: String
    var link: String
    @Published var episodes: [Episode]
    
    init(anime: Anime) {
        self.name = anime.name
        self.image = anime.image
        self.link = anime.link
        self.episodes = anime.episodes
    }
}

class EpisodeClass: ObservableObject {
    var name: String
    var thumb: String
    var videoLink: String
    var downloads: DownloadedVideo = DownloadedVideo()
    var visualized: Bool = false
    
    init(episode: Episode) {
        self.name = episode.name
        self.thumb = episode.thumb
        self.videoLink = episode.videoLink
        self.downloads = episode.downloads
        self.visualized = episode.visualized
    }
    
    func getStruct() -> Episode {
        return Episode(name: self.name, thumb: self.thumb, videoLink: self.videoLink, downloads: self.downloads, visualized: self.visualized)
    }
}
struct Manga: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var volumes: [Volume]
    
    func getClass() -> MangaClass {
        return MangaClass(manga: self)
    }
}

struct Volume: Codable, Hashable{
    var name: String
    var link: String
    var images: [URL]
    var downloadedImages: [String]
    var downloaded: Bool
    
    func getClass() -> VolumeClass {
        return VolumeClass(volume: self)
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
        return getMangasDirectory().appendingPathComponent(self.name, isDirectory: true)
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
    @Published var images: [URL]
    @Published var downloadedImages: [String]
    @Published var downloaded: Bool
    
    init(volume: Volume) {
        self.name = volume.name
        self.link = volume.link
        self.images = volume.images
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
    
    func getImages(completion: (() -> Void)? = nil) {
        guard let url = URL(string: link) else { return }
        self.images = []
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil, let html = String(data: data, encoding: .utf8) {
                do {
                    let imagesLinks = html.split(separator: "\\\"images\\\": ")[1].split(separator: "}")[0].replacing("\\", with: "")
                    let images = try JSONDecoder().decode([String].self, from: Data(imagesLinks.description.utf8))
                    for image in images {
                        if let imageUrl = URL(string: image) {
                            DispatchQueue.main.async {
                                self.images.append(imageUrl)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        completion?()
                    }
                } catch { }
            }
        }.resume()
    }
    
    func getStruct() -> Volume {
        return Volume(name: self.name, link: self.link, images: self.images, downloadedImages: self.downloadedImages, downloaded: self.downloaded)
    }
    
    func getDirectory(manga: MangaClass) -> URL {
        return manga.getDirectory().appendingPathComponent(self.name, isDirectory: true)
    }
}

enum Pages: CaseIterable {
    case Anime, Manga
    
    var unsIcon: String {
        switch self {
        case .Anime:
            return "play.circle"
        case .Manga:
            return "book"
        }
    }
    var selIcon: String {
        switch self {
        case .Anime:
            return "play.circle.fill"
        case .Manga:
            return "book.fill"
        }
    }
    var title: String {
        switch self {
        case .Anime:
            return "Anime"
        case .Manga:
            return "Mangá"
        }
    }
}

struct DownloadElement {
    let url: URL
    let saveAt: URL
    var volume: VolumeClass
}


class MangaURLSession: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published public var downloadTask: URLSessionDownloadTask?
    @Published public var progress: CGFloat = 0.0
    
    private var element: DownloadElement?
    private var elements: [DownloadElement] = []
    private var downloadCount: Int = 0
    
    private func reset() {
        self.downloadTask = nil
        self.progress = 0.0
        self.element = nil
        self.elements = []
        self.downloadCount = 0
    }
    
    func saveVolume() {
        if let element = self.element {
            DispatchQueue.main.async {
                let parts = element.saveAt.absoluteString.split(separator: "/")
                element.volume.downloadedImages.append(String(data: parts.last!.removingPercentEncoding!.data(using: .utf8)!, encoding: .utf8)!)
                MainViewModel.shared.saveMangas()
            }
        }
    }
    
    func downloadVolume(manga: MangaClass, volume: VolumeClass) {
        self.reset()
        volume.downloadedImages = []
        
        let volumePath = volume.getDirectory(manga: manga)
        
        var isDir: ObjCBool = true
        do {
            if !FileManager.default.fileExists(atPath: volumePath.path(), isDirectory: &isDir) {
                try FileManager.default.createDirectory(at: volumePath, withIntermediateDirectories: true)
            }
        } catch { }
        
        volume.getImages {
            for (i, image) in volume.images.enumerated() {
                let imageExtension = String(describing: image.absoluteString.split(separator: ".").last!)
                let imageName = "Imagem \(i+1).\(imageExtension)"
                self.elements.append(DownloadElement(url: image, saveAt: volumePath.appendingPathComponent(imageName), volume: volume))
            }
            self.startDownload()
        }
    }
    
    private func startDownload() {
        self.element = self.elements[self.downloadCount]
        DispatchQueue.main.async {
            self.downloadTask = URLSession(configuration: .default, delegate: self, delegateQueue: nil).downloadTask(with: self.element!.url)
            self.downloadTask!.resume()
        }
    }
    
    func cancel() {
        downloadTask?.cancel()
    }
    func pause() {
        downloadTask?.progress.pause()
    }
    func resume() {
        downloadTask?.resume()
    }
    
    // Finish
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.downloadCount += 1
        
        do {
            try FileManager.default.moveItem(at: location, to: self.element!.saveAt)
        } catch { }

        self.saveVolume()

        if self.downloadCount < self.elements.count {
            self.startDownload()
        } else {
            DispatchQueue.main.async {
                self.element!.volume.downloaded = true
                self.reset()
            }
        }
    }
    
    // Change
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress = (CGFloat(self.downloadCount) + progress) / CGFloat(self.elements.count)
        }
    }
}
