import SwiftUI
import UIKit
import ImageIO
import AVFoundation
import MobileCoreServices
public struct GIFView: UIViewRepresentable {
    private let data: Data
    private let repetitions: Int
    
    public init(
        data: Data,
        repetitions: Int = 0
    ) {
        self.data = data
        self.repetitions = repetitions
    }
    
    public func makeUIView(context: Context) -> UIGIFImageView {
        return UIGIFImageView(data: data, repetitions: repetitions)
    }
    
    public func updateUIView(_ uiView: UIGIFImageView, context: Context) {
        uiView.setImageData(data: data, repetitions: repetitions)
    }
}

public class UIGIFImageView: UIImageView {

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }
    
    convenience init(data: Data, repetitions: Int = 0) {
        self.init(frame: .zero)
        self.contentMode = .scaleAspectFit
        if let animation = UIImage.animatedImage(withData: data) {
            self.animationImages = animation.images
            self.animationDuration = animation.duration
            self.animationRepeatCount = repetitions
            self.image = animation.images?.last
            self.startAnimating()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImageData(data: Data,
                      repetitions: Int = 0){
        if let animation = UIImage.animatedImage(withData: data) {
            self.animationImages = animation.images
            self.animationDuration = animation.duration
            self.animationRepeatCount = repetitions
            self.image = animation.images?.last
            self.startAnimating()
        }
    }
    
}

extension UIImage {
    
    public class func animatedImage(withData: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(withData as CFData, nil) else {
            return nil
        }
        
        return UIImage.animatedImage(cgSource: source)
    }
    
    public class func animatedImage(withUrl: String) -> UIImage? {
        guard let bundleURL = URL(string: withUrl) else {
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            return nil
        }
        
        return animatedImage(withData: imageData)
    }
    
    public class func animatedImage(named: String) -> UIImage? {
        guard let bundleURL = Bundle.main.url(forResource: named, withExtension: "gif") else {
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            return nil
        }
        
        return animatedImage(withData: imageData)
    }
    
    fileprivate class func delay(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 1.0
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }
        
        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()), to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as? Double ?? 0
        
        if delay < 0.0 {
            delay = 1.0
        }
        
        return delay
    }
    
    fileprivate class func pair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a! < b! {
            let c = a
            a = b
            b = c
        }
        
        var r: Int
        while true {
            r = a! % b!
            
            if r == 0 {
                return b!
            } else {
                a = b
                b = r
            }
        }
    }
    
    fileprivate class func vector(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var p = array[0]
        
        for val in array {
            p = UIImage.pair(val, p)
        }
        
        return p
    }
    
    fileprivate class func animatedImage(cgSource: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(cgSource)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(cgSource, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delay(Int(i), source: cgSource)
            delays.append(Int(delaySeconds * 1000.0))
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = vector(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
        
        return animation
    }
    
}

public class GifTool{
    public static func createVideoFromGif(gifData: Data, completion: @escaping (URL?) -> Void) {
        guard let images = UIImage.animatedImage(withData: gifData)?.images else {
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
                let buffer = self.pixelBuffer(from: image, size: videoSize)
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
        
        completion(self.createGIF(from: frames))
    }

    static private func createGIF(from images: [UIImage], loopCount: Int = 0, frameDelay: Double = 0.1) -> Data? {
        let fileProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: loopCount
            ]
        ] as CFDictionary
        
        let frameProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDelay
            ]
        ] as CFDictionary
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, images.count, nil) else {
            return nil
        }
        
        CGImageDestinationSetProperties(destination, fileProperties)
        
        for image in images {
            if let cgImage = image.cgImage {
                CGImageDestinationAddImage(destination, cgImage, frameProperties)
            }
        }
        
        if !CGImageDestinationFinalize(destination) {
            return nil
        }
        
        return data as Data
    }
}
