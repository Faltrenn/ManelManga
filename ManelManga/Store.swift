//
//  Store.swift
//  ManelManga
//
//  Created by Emanuel on 17/09/23.
//

import Foundation
import SwiftUI

func getMangasDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Mangas", isDirectory: true)
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
            return "Animes"
        case .Manga:
            return "Mangás"
        }
    }
}

struct MangaURLQueue {
    var manga: MangaClass
    var volume: VolumeClass
    var downloading: Binding<Bool>
    var progress: Binding<CGFloat>
}

class MangaURLSession: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published public var downloadTask: URLSessionDownloadTask?
    @Binding private var downloading: Bool
    @Binding private var progress: CGFloat
    
    private var element: DownloadElement?
    private var elements: [DownloadElement] = []
    private var downloadCount: Int = 0
    
    private var queue: [MangaURLQueue] = []
    
    static var shared = MangaURLSession()
    
    private override init() {
        self._downloading = .constant(false)
        self._progress = .constant(.zero)
        super.init()
    }
    
    private func reset() {
        self.downloading = false
        self.downloadTask = nil
        self.progress = .zero
        self.element = nil
        self.elements = []
        self.downloadCount = 0
    }
    
    func saveVolume() {
        if let element = self.element {
            DispatchQueue.main.async {
                let parts = element.saveAt.absoluteString.split(separator: "/")
                element.volume.downloadedImages.append(String(data: parts.last!.removingPercentEncoding!.data(using: .utf8)!, encoding: .utf8)!)
            }
        }
    }
    
    func addVolumeToQueue(manga: MangaClass, volume: VolumeClass, downloading: Binding<Bool>, progress: Binding<CGFloat>) {
        self.queue.append(MangaURLQueue(manga: manga, volume: volume, downloading: downloading, progress: progress))
        self.startDownload()
    }
    
    private func downloadVolume(manga: MangaClass, volume: VolumeClass) {
        volume.downloadedImages = []
        
        DispatchQueue.main.async {
            let volumePath = volume.getDirectory(manga: manga)
            
            var isDir: ObjCBool = true
            do {
                if !FileManager.default.fileExists(atPath: volumePath.path(), isDirectory: &isDir) {
                    try FileManager.default.createDirectory(at: volumePath, withIntermediateDirectories: true)
                }
            } catch { }
            volume.getImages { imagesURLs in
                for (i, image) in imagesURLs.enumerated() {
                    let imageExtension = String(describing: image.absoluteString.split(separator: ".").last!)
                    let imageName = "Imagem \(i+1).\(imageExtension)"
                    self.elements.append(DownloadElement(url: image, saveAt: volumePath.appendingPathComponent(imageName), volume: volume))
                }
                self.downloadImage()
            }
        }
    }
    
    private func downloadImage() {
        self.element = self.elements[self.downloadCount]
        self.downloadTask = URLSession(configuration: .default, delegate: self, delegateQueue: nil).downloadTask(with: self.element!.url)
        self.downloadTask!.resume()
    }
    
    private func startDownload() {
        if !self.downloading {
            if let queueElement = self.queue.first {
                self._downloading = queueElement.downloading
                self._progress = queueElement.progress
                self.downloading = true
                self.downloadVolume(manga: queueElement.manga, volume: queueElement.volume)
            }
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
            self.downloadImage()
        } else {
            DispatchQueue.main.async {
                self.element!.volume.downloaded = true
                self.reset()
                self.queue.remove(at: 0)
                self.startDownload()
                MainViewModel.shared.saveMangas()
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
