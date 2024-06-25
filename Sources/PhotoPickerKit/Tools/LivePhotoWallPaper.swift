//
//  File.swift
//
//
//  Created by FunWidget on 2024/6/11.
//

import Foundation
import AVFoundation
import MobileCoreServices
import Photos
import ImageIO
import UniformTypeIdentifiers
import UIKit

public class LivePhotoUtil {
    
    public static func convertVideo(videoURL: URL, completion: @escaping (_ livePhoto: PHLivePhoto?, _ pairedImage: URL?, _ pairedVideo: URL?) -> Void) {
        print("start converting")
        clearCache()
        guard let metaURL = Bundle.module.url(forResource: "metadata", withExtension: "mov") else {
            print("Metadata URL not found")
            completion(nil, nil, nil)
            return
        }
        
        let livePhotoSize = CGSize(width: 1080, height: 1920)
        let livePhotoDuration = CMTimeMake(value: 1500, timescale: 600)
        let assetIdentifier = UUID().uuidString
        
        let durationPath = cacheDirectory()?.appendingPathComponent("duration").appendingPathExtension("mp4")
        let acceleratePath = cacheDirectory()?.appendingPathComponent("accelerate").appendingPathExtension("mp4")
        let resizePath = cacheDirectory()?.appendingPathComponent("resize").appendingPathExtension("mp4")
        
        guard let cacheDirectory = cacheDirectory(),let finalPath = resizePath, let resizePath = resizePath, let durationPath = durationPath, let acceleratePath = acceleratePath else {
            print("cacheDirectory URL not found")
            completion(nil, nil, nil)
            return
        }
        
        let converter = Converter4Video(path: finalPath)
        
        converter.durationVideo(inputURL: videoURL, outputURL: durationPath, targetDuration: 3) { success, error in
            guard success else {
                print("\(error?.localizedDescription ?? "")")
                completion(nil, nil, nil)
                return
            }
            
            converter.accelerateVideo(videoURL: durationPath, to: livePhotoDuration, outputURL: acceleratePath) { success, error in
                guard success else {
                    print("\(error?.localizedDescription ?? "")")
                    completion(nil, nil, nil)
                    return
                }
                
                converter.resizeVideo(inputURL: acceleratePath, outputURL: resizePath, outputSize: livePhotoSize) { success, error in
                    guard success else {
                        print("\(error?.localizedDescription ?? "")")
                        completion(nil, nil, nil)
                        return
                    }
                    
                    let asset = AVURLAsset(url: finalPath)
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.requestedTimeToleranceAfter = .zero
                    generator.requestedTimeToleranceBefore = .zero
                    
                    var times = [NSValue]()
                    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: asset.duration.timescale)
                    times.append(NSValue(time: time))
                    
                    let queue = DispatchQueue(label: "image", qos: .background)
                    var index = 0
                    
                    generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
                        guard let image = image else {
                            print("\(error?.localizedDescription ?? "")")
                            completion(nil, nil, nil)
                            return
                        }
                        
                        let picturePath = cacheDirectory.appendingPathComponent("live\(index)").appendingPathExtension("heic")
                        
                        let videoPath = cacheDirectory.appendingPathComponent("live\(index)").appendingPathExtension("mov")
                        
                        index += 1
                        
                        let converter4Image = Converter4Image(image: UIImage(cgImage: image))
                        
                        queue.async {
                            converter4Image.write(destURL: picturePath, assetIdentifier: assetIdentifier)
                            
                            converter.write(dest: videoPath, assetIdentifier: assetIdentifier, metaURL: metaURL) { success, error in
                                guard success else {
                                    print("\(error?.localizedDescription ?? "")")
                                    completion(nil, nil, nil)
                                    return
                                }
                                
                                _ = PHLivePhoto.request(withResourceFileURLs: [videoPath, picturePath], placeholderImage: nil, targetSize: CGSize.zero, contentMode: PHImageContentMode.aspectFit, resultHandler: { (livePhoto: PHLivePhoto?, info: [AnyHashable : Any]) -> Void in
                                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded {
                                        return
                                    }
                                     
                                    completion(livePhoto, picturePath, videoPath)
                                })
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    private static func cacheDirectory() -> URL?{
        if let cacheDirectoryURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fullDirectory = cacheDirectoryURL.appendingPathComponent("com.limit-point.LivePhoto", isDirectory: true)
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
                try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            return fullDirectory
        }
        return nil
    }
    
    private static func clearCache() {
        if let cacheDirectory = cacheDirectory() {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
    }
    
}

class Converter4Image {
    private let kFigAppleMakerNote_AssetIdentifier = "17"
    private let image : UIImage
    
    @objc init(image : UIImage) {
        self.image = image
    }
    
    @objc func read() -> String? {
        guard let makerNote = metadata(index: 0)?.object(forKey: kCGImagePropertyMakerAppleDictionary) as? NSDictionary else {
            return nil
        }
        return makerNote.object(forKey: kFigAppleMakerNote_AssetIdentifier) as? String
    }
    
    @objc func write(destURL : URL, assetIdentifier : String) {
        var type: CFString = kUTTypeJPEG
        if #available(iOS 16.0, *) {
            type = UTType.heic.identifier as CFString
        }
        
        guard let dest = CGImageDestinationCreateWithURL(destURL as CFURL, type, 1, nil) else { return }
        defer { CGImageDestinationFinalize(dest) }
        for i in 0...0 {
            guard let imageSource = self.imageSource() else { return }
            guard let metadata = self.metadata(index: i)?.mutableCopy() as? NSMutableDictionary else { return }
            
            let makerNote = NSMutableDictionary()
            makerNote.setObject(assetIdentifier, forKey: kFigAppleMakerNote_AssetIdentifier as NSCopying)
            metadata.setObject(makerNote, forKey: kCGImagePropertyMakerAppleDictionary as NSString)
            //            metadata.setObject("sRGB IEC61966-2.1", forKey: kCGImagePropertyProfileName as NSString)
            CGImageDestinationAddImageFromSource(dest, imageSource, i, metadata as CFDictionary)
        }
    }
    
    private func metadata(index: Int) -> NSDictionary? {
        return self.imageSource().flatMap {
            CGImageSourceCopyPropertiesAtIndex($0, index, nil) as NSDictionary?
        }
    }
    
    private func imageSource() -> CGImageSource? {
        return self.data().flatMap {
            CGImageSourceCreateWithData($0 as CFData, nil)
        }
    }
    
    private func data() -> Data? {
        if #available(iOS 17.0, *) {
            return image.heicData()
        } else {
            return image.pngData()
        }
    }
}

class Converter4Video {
    private let kKeyContentIdentifier =  "com.apple.quicktime.content.identifier"
    private let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    private let kKeySpaceQuickTimeMetadata = "mdta"
    private let path : URL
    
    private lazy var asset : AVURLAsset = {
        return AVURLAsset(url: path)
    }()
    
    @objc init(path : URL) {
        self.path = path
    }
    
    @objc func readAssetIdentifier() -> String? {
        for item in metadata() {
            if item.key as? String == kKeyContentIdentifier &&
                item.keySpace?.rawValue == kKeySpaceQuickTimeMetadata {
                return item.value as? String
            }
        }
        return nil
    }
    
    private func reader(track: AVAssetTrack, settings: [String:AnyObject]?) throws -> (AVAssetReader, AVAssetReaderOutput) {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        let reader = try AVAssetReader(asset: asset)
        reader.add(output)
        return (reader, output)
    }
    
    private func createMetadataAdaptorForStillImageTime() -> AVAssetWriterInputMetadataAdaptor {
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
                "\(keySpaceQuickTimeMetadata)/\(keyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
                "com.apple.metadata.datatype.int8"            ]
        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [spec] as CFArray, formatDescriptionOut: &desc)
        let input = AVAssetWriterInput(mediaType: .metadata,
                                       outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    private func metadataForAssetID(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyContentIdentifier =  "com.apple.quicktime.content.identifier"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
    
    private func metadataForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyStillImageTime as any NSCopying & NSObjectProtocol
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = kCMMetadataBaseDataType_SInt8 as String
        return item.copy() as! AVMetadataItem
    }
    
    @objc func write(dest: URL, assetIdentifier: String, metaURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        do {
            let metadataAsset = AVURLAsset(url: metaURL)
            
            let readerVideo = try AVAssetReader(asset: asset)
            let readerMetadata = try AVAssetReader(asset: metadataAsset)
            
            let writer = try AVAssetWriter(outputURL: dest, fileType: .mov)
            
            let writingGroup = DispatchGroup()
            
            var videoIOs = [(AVAssetWriterInput, AVAssetReaderTrackOutput)]()
            var metadataIOs = [(AVAssetWriterInput, AVAssetReaderTrackOutput)]()
            
            self.loadTracks(asset: self.asset, type: .video) { videoTracks in
                for track in videoTracks {
                    let trackReaderOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)])
                    readerVideo.add(trackReaderOutput)
                    
                    let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey : AVVideoCodecType.h264, AVVideoWidthKey : track.naturalSize.width, AVVideoHeightKey : track.naturalSize.height])
                    videoInput.transform = track.preferredTransform
                    videoInput.expectsMediaDataInRealTime = true
                    writer.add(videoInput)
                    
                    videoIOs.append((videoInput, trackReaderOutput))
                }
                
                self.loadTracks(asset: metadataAsset, type: .metadata) { metadataTracks in
                    for track in metadataTracks {
                        let trackReaderOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
                        readerMetadata.add(trackReaderOutput)
                        
                        let metadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil)
                        writer.add(metadataInput)
                        
                        metadataIOs.append((metadataInput, trackReaderOutput))
                    }
                    
                    writer.metadata = [self.metadataForAssetID(assetIdentifier)]
                    
                    writer.startWriting()
                    readerVideo.startReading()
                    readerMetadata.startReading()
                    writer.startSession(atSourceTime: .zero)
                    
                    for (videoInput, videoOutput) in videoIOs {
                        writingGroup.enter()
                        videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "assetWriterQueue.video")) {
                            while videoInput.isReadyForMoreMediaData {
                                if let sampleBuffer = videoOutput.copyNextSampleBuffer() {
                                    videoInput.append(sampleBuffer)
                                } else {
                                    videoInput.markAsFinished()
                                    writingGroup.leave()
                                    break
                                }
                            }
                        }
                    }
                    for (metadataInput, metadataOutput) in metadataIOs {
                        writingGroup.enter()
                        metadataInput.requestMediaDataWhenReady(on: DispatchQueue(label: "assetWriterQueue.metadata")) {
                            while metadataInput.isReadyForMoreMediaData {
                                if let sampleBuffer = metadataOutput.copyNextSampleBuffer() {
                                    metadataInput.append(sampleBuffer)
                                } else {
                                    metadataInput.markAsFinished()
                                    writingGroup.leave()
                                    break
                                }
                            }
                        }
                    }
                    
                    writingGroup.notify(queue: .main) {
                        if
                            readerVideo.status == .completed &&
                                readerMetadata.status == .completed &&
                                writer.status == .writing {
                            writer.finishWriting {
                                completion(writer.status == .completed, writer.error)
                            }
                        } else {
                            if let readerError = readerVideo.error {
                                completion(false, readerError)
                            } else if let readerError = readerMetadata.error {
                                completion(false, readerError)
                            } else if let writerError = writer.error {
                                completion(false, writerError)
                            } else {
                                completion(false, NSError(domain: "VideoProcessing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unkown error"]))
                            }
                        }
                    }
                }
            }
        } catch {
            completion(false, error)
        }
    }
    
    private func metadata() -> [AVMetadataItem] {
        return asset.metadata(forFormat: AVMetadataFormat.quickTimeMetadata)
    }
    
    private func degressFromVideoFileWithURL(videoTrack: AVAssetTrack)->Int {
        var degress = 0
        
        let t: CGAffineTransform = videoTrack.preferredTransform
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180
        }
        return degress
    }
    
    @objc public func cleanTransformVideo(inputURL: URL, outputURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        
        let asset = AVAsset(url: inputURL)
        self.loadTracks(asset: asset, type: .video) { videoTracks in
            guard let videoTrack = videoTracks.first else {
                completion(false, NSError(domain: "Clean Transform", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video track is not available"]))
                return
            }
            
            let videoComposition = AVMutableComposition()
            guard let track = videoComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                return
            }
            do {
                try track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration),
                                          of: videoTrack,
                                          at: .zero)
                track.preferredTransform = .identity
                
                let exportSession = AVAssetExportSession(asset: videoComposition, presetName: AVAssetExportPresetPassthrough)!
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mov
                
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            completion(true, nil)
                        case .failed:
                            completion(false, exportSession.error)
                        default:
                            break
                        }
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    @objc public func accelerateVideo(videoURL: URL, to duration: CMTime, outputURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let asset = AVAsset(url: videoURL)
        
        let composition = AVMutableComposition()
        self.loadTracks(asset: asset, type: .video) { videoTracks in
            do {
                guard let videoTrack = videoTracks.first else {
                    completion(false, NSError(domain: "Accelerate", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video track is not available"]))
                    return
                }
                
                let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video,
                                                                        preferredTrackID: kCMPersistentTrackID_Invalid)
                
                try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration),
                                                           of: videoTrack,
                                                           at: .zero)
                let targetDuration = duration
                
                compositionVideoTrack?.scaleTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration),
                                                      toDuration: targetDuration)
                compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
                
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mov
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        completion(true, nil)
                    case .failed:
                        completion(false, exportSession.error)
                    default:
                        completion(false, NSError(domain: "VideoProcessing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                    }
                }
                
            } catch {
                completion(false, error)
            }
        }
    }
    
    lazy private var cacheDirectory: URL? = {
        if let cacheDirectoryURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fullDirectory = cacheDirectoryURL.appendingPathComponent("com.limit-point.LivePhoto", isDirectory: true)
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
                try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            return fullDirectory
        }
        return nil
    }()
    
    @objc public func resizeVideo(inputURL: URL, outputURL: URL, outputSize: CGSize, completion: @escaping (Bool, Error?) -> Void) {
        
        let asset = AVAsset(url: inputURL)
        self.loadTracks(asset: asset, type: .video) { videoTracks in
            guard let videoTrack = videoTracks.first else {
                completion(false, NSError(domain: "Resize", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video track is not available"]))
                return
            }
            
            let originDegree = self.degressFromVideoFileWithURL(videoTrack: videoTrack)
            if originDegree != 0 {
                
                guard let tmpPath = self.cacheDirectory?.appendingPathComponent("tmp").appendingPathExtension("mp4") else{
                    return
                }
                
                self.cleanTransformVideo(inputURL: inputURL, outputURL: outputURL) { success, error in
                    self.rotateVideo(inputURL: tmpPath, outputURL: outputURL, degree: originDegree, completion: completion)
                }
                return
            }
            
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mov
            exportSession.shouldOptimizeForNetworkUse = true
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = outputSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            
            let preferredTransform = videoTrack.preferredTransform
            
            let originalSize = CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            let transformedSize = originalSize.applying(preferredTransform)
            let absoluteSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
            
            let widthRatio = outputSize.width / absoluteSize.width
            let heightRatio = outputSize.height / absoluteSize.height
            let scaleFactor = min(widthRatio, heightRatio)
            
            let newWidth = absoluteSize.width * scaleFactor
            let newHeight = absoluteSize.height * scaleFactor
            
            let translateX = (outputSize.width - newWidth) / 2
            let translateY = (outputSize.height - newHeight) / 2
            
            let translateTransform = CGAffineTransform(translationX: translateX, y: translateY).scaledBy(x: scaleFactor, y: scaleFactor)
            
            layerInstruction.setTransform(translateTransform, at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]
            
            exportSession.videoComposition = videoComposition
            
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        completion(true, nil)
                    case .failed:
                        completion(false, exportSession.error)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    @objc public func rotateVideo(inputURL: URL, outputURL: URL, degree: Int, completion: @escaping (Bool, Error?) -> Void) {
        
        let asset = AVAsset(url: inputURL)
        self.loadTracks(asset: asset, type: .video) { videoTracks in
            guard let videoTrack = videoTracks.first else {
                completion(false, NSError(domain: "Resize", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video track is not available"]))
                return
            }
            
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mov
            exportSession.shouldOptimizeForNetworkUse = true
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize =  abs(degree) == 90 ? CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width) : videoTrack.naturalSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            
            _ = CGAffineTransform(rotationAngle: Double.pi / 2)
            
            if (degree == 90) {
                layerInstruction.setTransform(CGAffineTransform(translationX: videoTrack.naturalSize.height, y: 0).rotated(by: .pi / 2), at: .zero)
            } else if (degree == -90) {
                layerInstruction.setTransform(CGAffineTransform(translationX: 0, y: videoTrack.naturalSize.width).rotated(by: -.pi / 2), at: .zero)
            } else {
                layerInstruction.setTransform(CGAffineTransform(translationX: videoTrack.naturalSize.width, y: videoTrack.naturalSize.height).rotated(by: .pi), at: .zero)
            }
            
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]
            
            exportSession.videoComposition = videoComposition
            
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        completion(true, nil)
                    case .failed:
                        completion(false, exportSession.error)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func loadTracks(asset: AVAsset, type: AVMediaType, completion: @escaping ([AVAssetTrack]) -> Void) {
        let tracksKey = #keyPath(AVAsset.tracks)
        if #available(iOS 15.0, *) {
            asset.loadTracks(withMediaType: type) { tracks, error in
                if let error = error {
                    print(error)
                }
                DispatchQueue.main.async {
                    completion(tracks ?? [])
                }
            }
        } else {
            asset.loadValuesAsynchronously(forKeys: [tracksKey]) {
                let status = asset.statusOfValue(forKey: "tracks", error: nil)
                if (status == .loaded) {
                    DispatchQueue.main.async {
                        print(asset) // <-- amazing trick
                        completion(asset.tracks(withMediaType: type))
                    }
                } else if (status == .cancelled) {
                    print("load tracks cancelled")
                } else if (status == .unknown) {
                    print("load tracks unknown")
                } else if (status == .failed) {
                    print("load tracks failed")
                }
            }
        }
    }
    
    @objc public func durationVideo(inputURL: URL, outputURL: URL, targetDuration: Double, completion: @escaping (Bool, Error?) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        let duration = asset.duration
        let timeScale = Int32(duration.timescale)
        
        let length = CMTimeGetSeconds(asset.duration)
        if length <= targetDuration {
            let composition = AVMutableComposition()
            
            guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            
            guard let assetTrack = asset.tracks(withMediaType: .video).first else { return }
            
            compositionTrack.preferredTransform = assetTrack.preferredTransform
            
            do {
                try compositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration),
                                                     of: assetTrack,
                                                     at: .zero)
            } catch {
                print("Failed to insert time range: \(error)")
                return
            }
            
            guard let firstFrame = getFrame(from: asset, at: CMTime(value: 0, timescale: timeScale)) else {
                return
            }
            guard let lastFrame = getFrame(from: asset, at: CMTimeSubtract(duration, CMTime(value: 1, timescale: timeScale))) else {
                return
            }
            
            guard let firstURL = self.cacheDirectory?.appendingPathComponent("first").appendingPathExtension("mp4"),
                  let lastURL = self.cacheDirectory?.appendingPathComponent("last").appendingPathExtension("mp4")else {
                return
            }
            
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: lastURL)
            
            let prefixDuration = CMTime(seconds: (targetDuration - duration.seconds) / 2, preferredTimescale: timeScale)
            let suffixDuration = CMTime(seconds: (targetDuration - duration.seconds) / 2, preferredTimescale: timeScale)
            
            self.createVideo(from: firstFrame, duration: CMTime(value: Int64(1 * timeScale), timescale: timeScale), outputURL: firstURL) { success in
                self.appendToComposition(compositionTrack, asset: AVAsset(url: firstURL), duration: prefixDuration, at: .zero)
                self.createVideo(from: lastFrame, duration: CMTime(value: Int64(1 * timeScale), timescale: timeScale), outputURL: lastURL) { success in
                    self.appendToComposition(compositionTrack, asset: AVAsset(url: lastURL), duration: suffixDuration, at: CMTimeAdd(prefixDuration, duration))
                    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
                    exporter?.outputURL = outputURL
                    exporter?.outputFileType = .mp4
                    exporter?.exportAsynchronously {
                        switch exporter?.status {
                        case .completed:
                            completion(true, nil)
                        default:
                            completion(false, exporter?.error)
                        }
                    }
                }
            }
        } else {
            
            let startTime = length / 2 - targetDuration / 2
            let endTime = length / 2 + targetDuration / 2
            
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.timeRange = CMTimeRangeFromTimeToTime(start: CMTimeMakeWithSeconds(startTime, preferredTimescale: timeScale), end: CMTimeMakeWithSeconds(endTime, preferredTimescale: timeScale))
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    completion(true, nil)
                default:
                    completion(false, exportSession.error)
                }
            }
        }
    }
    
    func getFrame(from asset: AVAsset, at timestamp: CMTime) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        var actualTime = CMTime.zero
        let cgImage = try? imageGenerator.copyCGImage(at: timestamp, actualTime: &actualTime)
        return cgImage.map(UIImage.init)
    }
    
    func appendToComposition(_ compositionTrack: AVMutableCompositionTrack, asset: AVAsset, duration: CMTime, at: CMTime) {
        guard let assetTrack = asset.tracks(withMediaType: .video).first else { return }
        
        let frameDuration = CMTime(value: 1, timescale: 30)
        var currentTime = at
        let endTime = CMTimeAdd(currentTime, duration)
        
        while currentTime < endTime {
            let nextTime = CMTimeAdd(currentTime, frameDuration)
            do {
                try compositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: frameDuration),
                                                     of: assetTrack,
                                                     at: currentTime)
            } catch {
                print("Error inserting time range: \(error)")
                return
            }
            currentTime = nextTime
        }
    }
    
    @objc func createVideo(from image: UIImage, duration: CMTime, outputURL: URL, completion: @escaping (Bool) -> Void) {
        let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(value: Float(image.size.width)),
            AVVideoHeightKey: NSNumber(value: Float(image.size.height))
        ])
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer?.add(writerInput)
        
        writer?.startWriting()
        writer?.startSession(atSourceTime: .zero)
        
        let buffer = pixelBuffer(from: image)
        
        var frameCount = 0.0
        let frameDuration = CMTime(value: 1, timescale: 30) // Example frame rate: 30 fps
        var presentTime = CMTime.zero
        
        writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "mediaInputQueue")) {
            while frameCount < duration.seconds * 30 { // 30 fps * duration in seconds
                if writerInput.isReadyForMoreMediaData {
                    if let buffer = buffer {
                        adaptor.append(buffer, withPresentationTime: presentTime)
                    }
                    presentTime = CMTimeAdd(presentTime, frameDuration)
                    frameCount += 1
                }
            }
            writerInput.markAsFinished()
            writer?.finishWriting {
                switch writer?.status {
                case .completed:
                    print("Video file created successfully.")
                    completion(true)
                default:
                    print("Failed to write video file: \(writer?.error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }
    
    func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
