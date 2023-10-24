//
//  AnimeStore.swift
//  ManelManga
//
//  Created by Emanuel on 16/10/23.
//

import Foundation
import SwiftUI

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

struct Source: Codable, Hashable {
    var file: String
    var type: String
    var label: String
}

struct DownloadedVideo: Codable, Hashable {
    var SD: String? = nil
    var HD: String? = nil
    var FHD: String? = nil
    
    mutating func set(source: Source, fileName: String) {
        if let quality = VideoQuality.getQuality(source: source) {
            switch quality {
            case .SD:
                SD = fileName
            case .HD:
                HD = fileName
            case .FHD:
                FHD = fileName
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

struct Episode: Codable, Hashable {
    var name: String
    var thumb: String
    var videoLink: String
    var downloads: DownloadedVideo = DownloadedVideo()
    var visualized: Bool = false
    
    func getClass() -> EpisodeClass {
        return EpisodeClass(episode: self)
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
    
    func getDirectory(anime: AnimeClass) -> URL {
        anime.getDirectory().appendingPathComponent(self.name, isDirectory: true)
    }
    
    func getStruct() -> Episode {
        return Episode(name: self.name, thumb: self.thumb, videoLink: self.videoLink, downloads: self.downloads, visualized: self.visualized)
    }
}

struct Anime: Codable, Hashable {
    var name: String
    var image: String
    var link: String
    var episodes: [Episode]
    
    func getClass() -> AnimeClass {
        return AnimeClass(anime: self)
    }
}

class AnimeClass: ObservableObject, Hashable {
    static func == (lhs: AnimeClass, rhs: AnimeClass) -> Bool {
        return lhs.name == rhs.name && lhs.link == rhs.link
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.link)
    }
    
    var name: String
    var image: String
    var link: String
    @Published var episodes: [EpisodeClass]
    
    init(anime: Anime) {
        self.name = anime.name
        self.image = anime.image
        self.link = anime.link
        self.episodes = []
        for episode in anime.episodes {
            self.episodes.append(episode.getClass())
        }
    }
    
    func getDownloadedEpisodePath(episode: EpisodeClass, quality: VideoQuality? = nil) -> URL? {
        if let fileName = episode.downloads.get(quality: quality) {
            return episode.getDirectory(anime: self).appendingPathComponent(fileName)
        }
        return nil
    }
    
    func getDirectory() -> URL {
        getAnimesDirectory().appendingPathComponent(self.name, isDirectory: true)
    }
    
    func getStruct() -> Anime {
        var episodes: [Episode] = []
        for episode in self.episodes {
            episodes.append(Episode(name: episode.name, thumb: episode.thumb, videoLink: episode.videoLink, downloads: episode.downloads, visualized: episode.visualized))
        }
        return Anime(name: self.name, image: self.image, link: self.link, episodes: episodes)
    }
}

struct AnimeURLQueue {
    var anime: AnimeClass
    var episode: EpisodeClass
    var source: Source
    var downloading: Binding<Bool>
    var progress: Binding<CGFloat>
}

struct AnimeDownloadElement {
    let source: Source
    let saveAt: URL
    var episode: EpisodeClass
}

class AnimeURLSession: NSObject, ObservableObject, URLSessionDownloadDelegate {
    private var downloadTask: URLSessionDownloadTask? = nil
    @Binding var progress: CGFloat
    @Binding var downloading: Bool
    
    private var element: AnimeDownloadElement? = nil
    
    private var queue: [AnimeURLQueue] = []
    
    static var shared = AnimeURLSession()
    
    private override init() {
        self._progress = .constant(.zero)
        self._downloading = .constant(false)
    }
    
    func addEpisodeToQueue(anime: AnimeClass, episode: EpisodeClass, source: Source, downloading: Binding<Bool>, progress: Binding<CGFloat>) {
        self.queue.append(AnimeURLQueue(anime: anime, episode: episode, source: source, downloading: downloading, progress: progress))
        self.startDownload()
    }
    
    private func startDownload() {
        if !self.downloading {
            if let queueElement = self.queue.first {
                let animePath = queueElement.episode.getDirectory(anime: queueElement.anime)
                do {
                    try FileManager.default.createDirectory(at: animePath, withIntermediateDirectories: true)
                } catch { }
                
                let episodeFileName = "\(queueElement.episode.name) \(queueElement.source.label).\(queueElement.source.type.split(separator: "/")[1])"

                self.element = AnimeDownloadElement(source: queueElement.source,
                                                    saveAt: animePath.appendingPathComponent(episodeFileName),
                                                    episode: queueElement.episode)
                self._downloading = queueElement.downloading
                self._progress = queueElement.progress
                self.downloading = true
                self.downloadTask = URLSession(configuration: .default, delegate: self, delegateQueue: nil).downloadTask(with: URL(string: queueElement.source.file)!)
                self.downloadTask?.resume()
            }
        }
    }
    
    private func reset() {
        self.downloading = false
        self.downloadTask = nil
        self.element = nil
        self.progress = .zero
    }
    
    private func saveEpisode() {
        if let element = self.element {
            element.episode.downloads.set(source: element.source, fileName: element.saveAt.lastPathComponent)
            MainViewModel.shared.saveAnimes()
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
        if let element = self.element {
            do {
                try FileManager.default.moveItem(at: location, to: element.saveAt)
            } catch { }
            
            self.saveEpisode()
            
            self.queue.removeFirst()
            self.reset()
            self.startDownload()
        }
    }
    
    // Change
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress = progress
        }
    }
}
