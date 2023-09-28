//
//  Store.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import Foundation

struct Manga: Hashable, Codable {
    var name: String
    var image: String
    var link: String
    var volumes: [Volume]
    
    func getClass() -> MangaClass {
        return MangaClass(manga: self)
    }
}

struct Volume: Codable, Hashable {
    var name: String
    var link: String
    var images: [URL]
    var downloadedImages: [URL]
    
    func getClass() -> VolumeClass {
        return VolumeClass(volume: self)
    }
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

class CustomURLSession: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0.0
    
    @Published var downloadTask: URLSessionDownloadTask?
    
    private var saveAt: URL?
    
    private var completion: ((_ savedAt: URL) -> Void)?
    
    private var imageId: Int?
    private var volume: VolumeClass?
    private var volumeUrl: URL?
    
    func getDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func downloadEpisode(anime: Anime, episode: Episode, source: Source, completion: ((_ savedAt: URL) -> Void)? = nil) {
        self.completion = completion
        var saveAt = getDirectory().appendingPathComponent(anime.name, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: saveAt, withIntermediateDirectories: true)
        } catch { }
        saveAt = saveAt.appendingPathComponent("\(episode.name).\(source.label.split(separator: "/")[1])")
        self.startDownlod(link: source.file, saveAt: saveAt)
    }
    
    func downloadVolume(manga: MangaClass, volume: VolumeClass, completion: ((_ savedAt: URL) -> Void)? = nil) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(manga.name, isDirectory: true)
            .appendingPathComponent(manga.name, isDirectory: true)
        self.completion = completion
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print(error)
        }
        
        self.imageId = 0
        self.volume = volume
        self.volumeUrl = url.appendingPathComponent(volume.name)
        do {
            try FileManager.default.createDirectory(at: self.volumeUrl!, withIntermediateDirectories: true)
        } catch {
            print(error)
        }
        let link = volume.images[0].absoluteString
        let parts = link.split(separator: ".")
        let urll = self.volumeUrl!.appendingPathComponent("Image \(imageId!).\(parts[2])")
        self.startDownlod(link: link, saveAt: urll)
    }
    
    func startDownlod(link: String, saveAt: URL) {
        guard let url = URL(string: link) else { return }
        
        downloadTask = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: .current).downloadTask(with: url)
        self.saveAt = saveAt
        DispatchQueue.global(qos: .background).async {
            self.downloadTask!.resume()
        }
    }
    
    func cancel() {
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        }
    }
    
    func pause() {
        if let downloadTask = downloadTask {
            downloadTask.progress.pause()
        }
    }
    func resume() {
        if let downloadTask = downloadTask {
            downloadTask.resume()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.moveItem(at: location, to: saveAt!)
        } catch { }
        
        if let completion = completion {
            completion(saveAt!)
        }
        
        DispatchQueue.main.async {
            self.volume!.downloadedImages.append(self.saveAt!)
            
            if self.imageId != nil, self.imageId! + 1 < self.volume!.images.count {
                self.imageId! += 1
                let link = self.volume!.images[self.imageId!].absoluteString
                let parts = link.split(separator: ".")
                self.startDownlod(link: link, saveAt: self.volumeUrl!.appendingPathComponent("Image \(self.imageId!).\(parts[2])"))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress = progress
        }
    }
}
