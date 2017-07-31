//
//  ImagePicker.swift
//
//  Created by Aleksandr on 27/07/2017.
//  Copyright © 2017 Aleksandr Makarov. All rights reserved.
//

import Photos

/*!
 @class        MLImagePicker
 @abstract     MLImagePicker provides access to the camera, the user's photo library and returns the URL of the file of the created or selected content.
 @discussion   ...
 */
open class MLImagePicker {

    open var picker: UIImagePickerController!

    fileprivate var parentController: UIViewController?
    fileprivate var completion: ((_ url: URL?) -> Void)?
    fileprivate var fileUrl: URL?
    fileprivate var strongSelf: MLImagePicker?
    fileprivate var imagePickerDelegate = MLImagePickerDelegate()
    
    public init() {
        
        picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image", "public.movie"]
    }
    
    open func presentInController(_ controller: UIViewController, completion: ((_ fileUrl: URL?) -> Void)?) {
        
        parentController = controller
        self.completion = completion
        
        imagePickerDelegate.completion = { [weak self] (fileUrl) in
            self?.fileUrl = self?.copyToCacheFileURL(fileUrl)
            self?.dismiss()
        }
        
        picker.delegate = imagePickerDelegate
        
        parentController?.present(picker, animated: true) {
            self.strongSelf = self;
        }
    }
    
    func dismiss () {
        
      //  print("MLImagePicker file path: \(self.fileUrl?.absoluteString ?? "")")
        
        DispatchQueue.main.async {
            
            self.parentController?.dismiss(animated: true, completion: {
                self.completion?(self.fileUrl)
                self.strongSelf = nil
            })
        }
    }
    
    func copyToCacheFileURL (_ fileUrl: URL?) -> (URL?) {
        
        do {
            
            guard let fileName = fileUrl?.lastPathComponent
                else { return nil }
            
            var cacheUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            cacheUrl.appendPathComponent(String(describing: self))
            
            if FileManager.default.fileExists(atPath: cacheUrl.path) == false {
                // create directory
                try FileManager.default.createDirectory(at: cacheUrl, withIntermediateDirectories: true, attributes: nil)
            }
            
            cacheUrl.appendPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: cacheUrl.path) == true {
                // remove file
                try FileManager.default.removeItem(at: cacheUrl)
            }
            
            try FileManager.default.copyItem(at: fileUrl!, to: cacheUrl)
            
            return cacheUrl
            
        } catch let error {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
}

class MLImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    fileprivate var completion: ((_ fileUrl: URL?) -> Void)?
    
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
