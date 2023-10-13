//
//  TestView.swift
//  ManelManga
//
//  Created by Emanuel on 27/09/23.
//

import SwiftUI

struct TestView: View {
    @ObservedObject var session = MangaURLSession()
    
    let manga = Manga(name: "Manga",
                      image: "",
                      link: "",
                      volumes: [
                        Volume(name: "Volume 0",
                               link: "",
                               images: [
                                URL(string: "https://dn1.imgstatic.club/uploads/j/jibaku-shounen-hanako-kun/0/1.png")!,
                                URL(string: "https://dn1.imgstatic.club/uploads/j/jibaku-shounen-hanako-kun/0/2.png")!,
                               ],
                               downloadedImages: []),
                        Volume(name: "Volume 1",
                               link: "",
                               images: [
                                URL(string: "https://dn1.imgstatic.club/uploads/j/jibaku-shounen-hanako-kun/0/3.png")!,
                                URL(string: "https://dn1.imgstatic.club/uploads/j/jibaku-shounen-hanako-kun/0/4.png")!
                               ],
                               downloadedImages: [])
                      ]).getClass()
    
    var body: some View {
        ScrollView {
            ProgressView(value: session.progress)
            ForEach(manga.volumes, id:\.self) { volume in
                Text(volume.name)
                    .font(.title)
                ForEach(volume.downloadedImages, id: \.self) { url in
                    Text(url.absoluteString)
                    AsyncImage(url: url) {image in
                        image
                            .resizable()
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
            Button("Baixar volume 0") {
//                session.downloadVolume(manga: manga, volume: manga.volumes[0])
            }
            Button("Baixar volume 1") {
//                session.downloadVolume(manga: manga, volume: manga.volumes[1])
            }
            
        }
    }
}

func getDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Mangas", isDirectory: true)
}


class MangaURLSession: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published public var downloadTask: URLSessionDownloadTask?
    @Published public var progress: CGFloat = 0.0
    
    private var element: DownloadElement?
    private var elements: [DownloadElement] = []
    private var downloadCount: Int = 0
    
    private var mainViewModel: MainViewModel?
    
    private func reset() {
        DispatchQueue.main.async {
            self.downloadTask = nil
            self.progress = 0.0
        }
        self.element = nil
        self.elements = []
        self.downloadCount = 0
    }
    
    func saveVolume() {
        if let element = self.element {
            DispatchQueue.main.async {
                let parts = element.saveAt.absoluteString.split(separator: "/")
                element.volume.downloadedImages.append(String(data: parts.last!.removingPercentEncoding!.data(using: .utf8)!, encoding: .utf8)!)
                if let mainViewModel = self.mainViewModel {
                    mainViewModel.saveMangas()
                }
            }
        }
    }
    
    func downloadVolume(manga: MangaClass, volume: VolumeClass, mainViewModel: MainViewModel) {
        self.reset()
        volume.downloadedImages = []
        
        self.mainViewModel = mainViewModel
        
        let volumePath = getMangaDirectory().appendingPathComponent(manga.name, isDirectory: true).appendingPathComponent(volume.name, isDirectory: true)
        
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
        self.progress = CGFloat(self.downloadCount) / CGFloat(self.elements.count)
        
        do {
            try FileManager.default.moveItem(at: location, to: self.element!.saveAt)
        } catch { }

        self.saveVolume()

        if self.downloadCount < self.elements.count {
            self.startDownload()
        } else {
            reset()
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


#Preview {
    TestView()
}
