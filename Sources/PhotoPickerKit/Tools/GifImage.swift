import SwiftUI
import UIKit
import ImageIO
import AVFoundation
import MobileCoreServices
import BrickKit

extension GifTool{

    public static func createVideoFromGif(gifData: Data, completion: @escaping (URL?) -> Void) {
        guard let images = gifImage(data: gifData)?.frames else {
            completion(nil)
            return
        }
        
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let outputURL = temporaryDirectoryURL.appendingPathComponent("gif.MOV")
        try? FileManager.default.removeItem(at: outputURL)
        
        let videoSize = images[0].size
        let videoDuration = Double(images.count) / 10.0 // Adjust frame rate as needed
        
        let writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let settings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(value: Float(videoSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(videoSize.height))
        ] as [String : Any]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let sourceBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Float(videoSize.width),
            kCVPixelBufferHeightKey as String: Float(videoSize.height)
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(seconds: videoDuration / Double(images.count), preferredTimescale: 600)
        var frameCount = 0
        
        writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "mediaInputQueue")) {
            while writerInput.isReadyForMoreMediaData {
                if frameCount >= images.count {
                    writerInput.markAsFinished()
                    writer.finishWriting {
                        completion(outputURL)
                    }
                    break
                }
                
                let image = images[frameCount]
                let buffer = pixelBuffer(from: image, size: videoSize)
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                
                adaptor.append(buffer, withPresentationTime: presentationTime)
                frameCount += 1
            }
        }
    }
    
    static private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer {
        let options: [NSObject: AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ]
        var pxbuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pxbuffer)
        guard status == kCVReturnSuccess, let buffer = pxbuffer else {
            fatalError("Failed to create pixel buffer")
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pxdata = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
    
    public static func createGifData(from videoURL: URL, completion: @escaping (Data?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let assetReader = try! AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: .video).first!
        
        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let assetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        assetReader.add(assetReaderOutput)
        assetReader.startReading()
        
        var frames: [UIImage] = []
        
        while let sampleBuffer = assetReaderOutput.copyNextSampleBuffer(), let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            let uiImage = UIImage(cgImage: cgImage)
            frames.append(uiImage)
        }
        
        completion(createGIF(with: frames))
    }
}
