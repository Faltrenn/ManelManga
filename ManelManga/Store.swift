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

struct DownloadedVideo: Codable, Hashable {
    var SD: String? = nil
    var HD: String? = nil
    var FHD: String? = nil
    var downloaded: Bool { return (SD != nil || HD != nil || FHD != nil) }
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
    
    func getDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func downloadEpisode(anime: Anime, episode: Episode, source: Source, completion: ((_ savedAt: URL) -> Void)? = nil) {
        self.completion = completion
        var saveAt = getDirectory().appendingPathComponent(anime.name, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: saveAt, withIntermediateDirectories: true)
        } catch { }
        saveAt = saveAt.appendingPathComponent("\(episode.name).\(source.type.split(separator: "/")[1])")
        self.startDownlod(link: source.file, saveAt: saveAt)
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
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress = progress
        }
    }
}
