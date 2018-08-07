//
//  MLImagePickerDelegate.swift
//  MLImagePicker
//
//  Created by Aleksandr on 02/08/2017.
//  Copyright © 2017 Aleksandr. All rights reserved.
//

import Photos

class MLImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var completion: ((_ fileUrl: URL?) -> Void)?
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let url = info[UIImagePickerControllerReferenceURL] as? URL {
            // libriary photo, video
            let asset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject
            
            fileUrlWithAsset(asset) { (fileUrl) in
                self.completion?(fileUrl)
            }
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // camera photo
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { saved, error in

                if saved == true {
                    let asset = self.getLastAssetWithMediaType(.image)
                    self.fileUrlWithAsset(asset) { (fileUrl) in
                        self.completion?(fileUrl)
                    }
                } else {
                    self.completion?(nil)
                }
            }
            
        } else if let url = info[UIImagePickerControllerMediaURL] as? URL {
            // camera video
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                
                if saved == true {
                    let asset = self.getLastAssetWithMediaType(.video)
                    self.fileUrlWithAsset(asset) { (fileUrl) in
                        self.completion?(fileUrl)
                    }
                } else {
                    self.completion?(nil)
                }
            }
        } else {
            completion?(nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        completion?(nil)
    }
}

extension MLImagePickerDelegate {

    func getLastAssetWithMediaType (_ type: PHAssetMediaType) -> (PHAsset?) {
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        return PHAsset.fetchAssets(with: type, options: fetchOptions).firstObject
    }

    func fileUrlWithAsset (_ asset: PHAsset?, completion: ((_ fileUrl: URL?) -> Void)?) {
        if let asset = asset {
            if asset.mediaType == .image {
                asset.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    completion?(contentEditingInput?.fullSizeImageURL)
                })
            } else {
                let options = PHVideoRequestOptions()
                options.version = .original

                PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset, audioMix, hashable) in

                    var url: URL?
                    if let urlAsset = asset as? AVURLAsset {
                        url = urlAsset.url
                    }
                    completion?(url)
                })
            }
        } else {
            completion?(nil)
        }
    }
}
