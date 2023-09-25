//
//  SwiftUIView.swift
//  ManelManga
//
//  Created by Emanuel on 24/09/23.
//

import SwiftUI

struct Episode2: Hashable, Codable {
    var name: String
    var videoLink: String
    var downloadedVideoLink: String
    var visualized: Bool
}

struct Anime2: Hashable, Codable {
    var name: String
    var episodes: [Episode2]
}

class Model: ObservableObject {
    @Published var animes = [Anime2(name: "A",
                                  episodes: [
                                   Episode2(name: "a",
                                            videoLink: "",
                                            downloadedVideoLink: "a",
                                            visualized: false),
                                   Episode2(name: "b",
                                            videoLink: "",
                                            downloadedVideoLink: "b",
                                            visualized: false)
                                  ]),
                    Anime2(name: "AA",
                           episodes: [
                               Episode2(name: "c",
                                        videoLink: "",
                                        downloadedVideoLink: "c",
                                        visualized: false),
                               Episode2(name: "d",
                                        videoLink: "",
                                        downloadedVideoLink: "d",
                                        visualized: false)])]
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

struct Test: View {
    @ObservedObject var model = Model()
    
    @ObservedObject var session = CustomURLSession()
    
    var body: some View {
        VStack {
            ProgressView(value: session.progress)
            Text("\(session.progress)")
            Button("Cancel") {
                session.cancel()
            }
            Button("Pause") {
                session.pause()
            }
            Button("Resume") {
                session.resume()
            }
            
            Menu{
                Button {
                    session.startDownlod(link: "https://static.vecteezy.com/system/resources/previews/021/723/048/mp4/hi-speed-5g-speed-test-network-technology-10gbps-speed-meter-free-video.mp4",
                                         saveAt: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Video2.mp4"))
                } label: {
                    Text("Baixar Video")
                }

            } label: {
                Image(systemName: "arrow.down.to.line")
                    .bold()
                    .padding(5)
                    .overlay {
                        Circle()
                            .trim(from: 0, to: session.progress)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(Angle(degrees: -90))
                            .animation(.easeIn(duration: 0.15), value: session.progress)
                    }
            }
        }
    }
}

struct Test_Previews: PreviewProvider {
    static var previews: some View {
        Test()
    }
}
