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
