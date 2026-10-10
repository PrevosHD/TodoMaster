//
//  MediaPicking.swift
//  TodoMaster
//

import AVFoundation
import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Medium im Editor. `isExisting` heißt: gehört schon zu einer gespeicherten Todo.
struct DraftMedia: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let kind: MediaKind
    let isExisting: Bool

    var fileURL: URL { MediaStore.url(for: fileName) }
}

struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let fileName = try MediaStore.importFile(at: received.file)
            return PickedVideo(url: MediaStore.url(for: fileName))
        }
    }
}

enum MediaImporter {
    static func importItem(_ item: PhotosPickerItem) async -> DraftMedia? {
        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
        if isVideo {
            guard let video = try? await item.loadTransferable(type: PickedVideo.self) else { return nil }
            return DraftMedia(fileName: video.url.lastPathComponent, kind: .video, isExisting: false)
        }
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let jpeg = image.jpegData(compressionQuality: 0.85),
            let fileName = try? MediaStore.save(data: jpeg, fileExtension: "jpg")
        else { return nil }
        return DraftMedia(fileName: fileName, kind: .image, isExisting: false)
    }
}

struct MediaThumbnail: View {
    let url: URL
    let kind: MediaKind

    @State private var image: UIImage?

    /// Feste quadratische Zelle. Das Bild füllt sie und wird mittig beschnitten, egal ob Hoch- oder Querformat.
    var body: some View {
        Color(.secondarySystemBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                }
            }
            .overlay {
                if kind == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        .task(id: url) {
            image = await Self.loadThumbnail(url: url, kind: kind)
        }
    }

    private static func loadThumbnail(url: URL, kind: MediaKind) async -> UIImage? {
        switch kind {
        case .image:
            return await Task.detached {
                UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: CGSize(width: 300, height: 300))
            }.value
        case .video:
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 300, height: 300)
            guard let cgImage = try? await generator.image(at: .zero).image else { return nil }
            return UIImage(cgImage: cgImage)
        }
    }
}
