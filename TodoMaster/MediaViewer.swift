//
//  MediaViewer.swift
//  TodoMaster
//

import AVKit
import SwiftUI

struct MediaViewer: View {
    let media: DraftMedia

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                switch media.kind {
                case .image:
                    if let image = UIImage(contentsOfFile: media.fileURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                case .video:
                    if let player {
                        VideoPlayer(player: player)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            if media.kind == .video {
                let player = AVPlayer(url: media.fileURL)
                self.player = player
                player.play()
            }
        }
        .onDisappear {
            player?.pause()
        }
    }
}
