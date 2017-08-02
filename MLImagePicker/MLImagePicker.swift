//
//  ImagePicker.swift
//
//  Created by Aleksandr on 27/07/2017.
//  Copyright © 2017 Aleksandr Makarov. All rights reserved.
//

import MobileCoreServices

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
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
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
