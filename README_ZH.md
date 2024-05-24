# PhotoPickerKit


[![SPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager/)
![Xcode 14.0+](https://img.shields.io/badge/Xcode-14.0%2B-blue.svg)
![iOS 14.0+](https://img.shields.io/badge/iOS-14.0%2B-blue.svg)
![Swift 5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange.svg)
![SwiftUI 3.0+](https://img.shields.io/badge/SwiftUI-3.0%2B-orange.svg)

## 例子

SwiftUI封装完相册后当用户手机内相册存储的照片视频达到一定的数量及（例如150G以上，两万张照片视频左右），LazyVGrid就会陷入一个运算艰难的境地，CPU占用居高不下，暂时没找到很好的优化办法，所以就用UIKit又封装了一遍，看实际需求酌情使用,Demo在[SwiftUI封装](https://github.com/zjinhu/PhotoPicker_SwiftUI)

打开使用封装的相册

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

打开系统相册

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

进入照片视频编辑工具

```swift
        .editPicker(isPresented: $isPresentedCrop,
                    cropRatio: .init(width: 10, height: 1),
                    asset: selectItem.selectedAsset) { asset in
            selectItem.pictures.replaceSubrange(selectItem.selectedIndex...selectItem.selectedIndex, with: [asset])
        }
```



## 用法


## 安装

在 Xcode 的菜单栏中选择 `File > Swift Packages > Add Pacakage Dependency`，然后在搜索栏输入

`https://github.com/jackiehu/PhotoPickerKit`

### 手动集成

PhotoPicker_SwiftUI 也支持手动集成，只需把Sources文件夹中的PhotoPicker_SwiftUI文件夹拖进需要集成的项目即可


## 作者

hu, 

## 更多砖块工具加速APP开发

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftMediator&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftMediator)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftBrick&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftBrick)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftLog&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftLog)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftMesh&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftMesh)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftNotification&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftNotification)




## 许可

PhotoPicker_SwiftUI is available under the MIT license. See the LICENSE file for more info.
