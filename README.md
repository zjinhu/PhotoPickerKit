# PhotoPickerKit


[![SPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager/)
![Xcode 14.0+](https://img.shields.io/badge/Xcode-14.0%2B-blue.svg)
![iOS 14.0+](https://img.shields.io/badge/iOS-14.0%2B-blue.svg)
![Swift 5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange.svg)
![SwiftUI 3.0+](https://img.shields.io/badge/SwiftUI-3.0%2B-orange.svg)

## [中文说明](https://github.com/zjinhu/PhotoPickerKit/blob/main/README_ZH.md)

## Example

SwiftUI package after the album when the user's cell phone album storage of photos and videos to reach a certain number and (for example, more than 150G, 20,000 photos and videos or so), LazyVGrid will fall into an arithmetic difficult situation, the CPU occupancy remains high, and temporarily did not find a good way to optimize, so it is packaged again with UIKit, to see the actual needs of the discretionary use 。[SwiftUI Demo](https://github.com/zjinhu/PhotoPicker_SwiftUI)

Open the custom album

```swift
                Button {
                    isPresentedGallery.toggle()
                } label: {
                    Text("打开自定义相册UIKit")
                        .foregroundColor(Color.red)
                        .frame(height: 50)
                }
                .galleryPicker(isPresented: $isPresentedGallery,
                                   maxSelectionCount: 9,
                                   selectTitle: "Videos",
                                   autoCrop: true,
                                   cropRatio: .init(width: 1, height: 1),
                                   onlyImage: false,
                                   selected: $selectItem.pictures)
```

Open the system album

```swift
                Button {
                    showPicker.toggle()
                } label: {
                    Text("打开系统相册")
                }
                .photoPicker(isPresented: $showPicker,
                             selected: $selectedItems,
                             maxSelectionCount: 5,
                             matching: .any(of: [.images, .livePhotos, .videos]))
                .onChange(of: selectedItems) { newItems in
                    var images = [UIImage]()
                    Task{
                        for item in newItems{
                            if let image = try await item.loadTransfer(type: UIImage.self){
                                images.append(image)
                            }
                        }
                        await MainActor.run {
                            selectedImages = images
                        }
                    }
                }
```

Access to photo video editing tools

```swift
        .editPicker(isPresented: $isPresentedCrop,
                    cropRatio: .init(width: 10, height: 1),
                    asset: selectItem.selectedAsset) { asset in
            selectItem.pictures.replaceSubrange(selectItem.selectedIndex...selectItem.selectedIndex, with: [asset])
        }
```

## Usage


## Install

Select `File > Swift Packages > Add Pacakage Dependency` in Xcode's menu bar, and enter in the search bar

`https://github.com/jackiehu/PhotoPickerKit`, you can complete the integration

### Manual Install

PhotoPicker_SwiftUI also supports manual Install, just drag the PhotoPicker_SwiftUI folder in the Sources folder into the project that needs to be installed


## Author

hu, 

## More tools to speed up APP development

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftMediator&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftMediator)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftBrick&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftBrick)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftLog&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftLog)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftMesh&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftMesh)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftNotification&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftNotification)


## 许可

PhotoPicker_SwiftUI is available under the MIT license. See the LICENSE file for more info.
