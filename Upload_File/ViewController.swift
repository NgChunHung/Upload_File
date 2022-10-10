//
//  ViewController.swift
//  Upload_File
//
//  Created by Tommy NG on 24/8/2022.
//

import UIKit
import WebKit
import MobileCoreServices
import PhotosUI
import Photos
import AVKit
import UniformTypeIdentifiers

@available(iOS 14.5, *)
class ViewController: UIViewController, WKUIDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate, WKNavigationDelegate, WKScriptMessageHandler, UIDocumentPickerDelegate{
    
    var webView : WKWebView!

    // Showing choices
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let alert = UIAlertController(title: "Notice", message: "Which type of data you want to compress?", preferredStyle: UIAlertController.Style.alert)
        //Choices
        alert.addAction(UIAlertAction(title: "Take Photo", style: UIAlertAction.Style.default, handler: setFilter))
        alert.addAction(UIAlertAction(title: "Take Video", style: UIAlertAction.Style.default, handler: setFilter))
        alert.addAction(UIAlertAction(title: "Choose Media From Album", style: UIAlertAction.Style.default, handler: setFilter))
        alert.addAction(UIAlertAction(title: "Choose File", style: UIAlertAction.Style.default, handler: setFilter))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:nil))
        self.present(alert, animated: true)
        
    }
    

    // After choose a choice, action
    func setFilter(_ action: UIAlertAction) {
        let selectedActionTitle = action.title
        print(selectedActionTitle!)
        
        if selectedActionTitle=="Take Photo"
        {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate=self
            imagePicker.allowsEditing=false
            present(imagePicker,animated:true, completion: nil)
            
        }
        
        
        
        else if selectedActionTitle=="Take Video"{
            
            let imagePicker = UIImagePickerController()
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                if (UIImagePickerController.availableCaptureModes(for: .rear) != nil){
                    
                    imagePicker.delegate=self
                    imagePicker.mediaTypes=[kUTTypeMovie as String]
                    imagePicker.sourceType=UIImagePickerController.SourceType.camera
                    imagePicker.allowsEditing=false
                    self.present(imagePicker,animated:true,completion:nil)
                    
                    
                }
            }
            
            
        }else if selectedActionTitle=="Choose Media From Album"{
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate=self
            imagePicker.allowsEditing=false
            imagePicker.mediaTypes = ["public.image", "public.movie"]
            present(imagePicker,animated:true, completion: nil)
            
            
        }else if selectedActionTitle=="Choose File"{
            
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: false)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = .formSheet
            
            self.present(documentPicker, animated: true, completion: nil)
            
            
        }
        
    }
    
    
    
    
    
    // After chosed photo or video from camera or library
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        
        if let image = info[.originalImage] as? UIImage {
            let url = ConvertImageToUrl(image)
            uploadImage(imageURL: url!)
            print("taking image")
            
        }
        
        else if let selectedVideoUrl:URL = (info[UIImagePickerController.InfoKey.mediaURL] as? URL) {
            print("taking video")
            uploadVideo(videoURL: selectedVideoUrl)
            
        }
        
        
        
        // convert image to url
        func ConvertImageToUrl(_ image: UIImage) -> (URL)? {
            guard let imageData = image.jpegData(compressionQuality: 1) else {
                return nil
            }
            do {
                //save image url to temp folder as jpg
                let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(Int(Date().timeIntervalSince1970)).jpg")
                try imageData.write(to: imageURL)
                return imageURL
            } catch {
                print("it has error")
                print(error)
                return nil
            }
        }
        
    }
    
    
    // choose file from ios document
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        //get the url from url[]
        let url = urls.first!
        
        //check whether system can visit the url or not
        guard url.startAccessingSecurityScopedResource() else {
            print("can't access")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        
        let imageExtensions = ["png", "jpg", "gif"]
        let videoExtensions = ["mov", "mp4", "avi"]
        //get path extension and lowercase it
        let extent = url.pathExtension.lowercased()
        print(extent)
        
        let fileName = "\(Int(Date().timeIntervalSince1970)).\(extent)"
        // create new URL
        let newurl = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
        // copy item to APP Storage
        try? FileManager.default.copyItem(at: url, to: newurl)
        
        if imageExtensions.contains(extent)
        {
            
            uploadImage(imageURL: newurl)
            print("image in document")
            
        }else if videoExtensions.contains(extent)
        {
            uploadVideo(videoURL: newurl)
            print("video in docuemt")
        }else{
            //Alert
            let alert = UIAlertController(title: "Cannot Upload", message: "You cannot upload non-image or non-video file", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OKay", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true)
            
        }
        
    }
    
    
    
    // Request authorization of album
    func requestAuthorization(completion: @escaping ()->Void) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else if PHPhotoLibrary.authorizationStatus() == .authorized{
            completion()
        }
    }
    
    
    // saving image from app to album
    func saveMediaFileToAlbum(pathExtension:String,outputURL: URL, _ completion: ((Error?) -> Void)?) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                print(pathExtension)
                let request = PHAssetCreationRequest.forAsset()
                let imageExtensions = ["png", "jpg", "gif"]
                let videoExtensions = ["mov", "mp4", "avi"]
                //if file is image
                if imageExtensions.contains(pathExtension.lowercased())
                {
                    request.addResource(with: .photo, fileURL: outputURL, options: nil)
                //if file is video
                }else if videoExtensions.contains(pathExtension.lowercased())
                {
                    request.addResource(with: .video, fileURL: outputURL, options: nil)
                }
                
            }) { (result, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                        print("failed to save image")
                    } else {
                        print("Saved successfully")
                    }
                    completion?(error)
                }
            }
        }
    }
    
    
    

    
    

    // Hide and remove the previous image
    func hiddenImage(){
        DispatchQueue.main.async {
            let remove1="document.getElementById('myImg').removeAttribute('src');"
            self.webView.evaluateJavaScript(remove1, completionHandler:nil)
            let hidden1="document.getElementById('myImg').style.display = 'none';"
            self.webView.evaluateJavaScript(hidden1, completionHandler:nil)
            let hidden2="document.getElementById('ImageSize').style.display = 'none';"
            self.webView.evaluateJavaScript(hidden2, completionHandler:nil)
            
        }
        
    }
    
    // Hide and remove the previous video
    func hiddenVideo(){
        DispatchQueue.main.async {
            let remove1="document.getElementById('video').removeAttribute('src');"
            self.webView.evaluateJavaScript(remove1, completionHandler:nil)
            let hidden1="document.getElementById('video').style.display = 'none';"
            self.webView.evaluateJavaScript(hidden1, completionHandler:nil)
            let hidden2="document.getElementById('OrginalVideoSize').style.display = 'none';"
            self.webView.evaluateJavaScript(hidden2, completionHandler:nil)
            
            let hidden4="document.getElementById('CompressedVideoSize').style.display = 'none';"
            self.webView.evaluateJavaScript(hidden4, completionHandler:nil)
        }
    }
    
    
    
    // Upload Compressed video to local html
    func uploadVideo(videoURL:URL){
        hiddenImage()
        // create temp url for store the compressed url
        let newUrl = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
        let fileName = "\(Int(Date().timeIntervalSince1970)).\(videoURL.pathExtension)"
        
        // create temp url for saving the app url
        let urlToBeCompressed = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
        
        // copy app url to temp url
        try? FileManager.default.copyItem(at: videoURL, to: urlToBeCompressed)


        // save non-compressed video now
        let extent = videoURL.pathExtension.lowercased()
        self.saveMediaFileToAlbum(pathExtension: extent,outputURL: videoURL){(error) in
            print(error as Any)
            print("download non-compressed video from app to album")
        }
      
        
        
        // compress video
        compressVideo(inputURL: urlToBeCompressed,
                      outputURL: newUrl) { exportSession in
            guard let session = exportSession else {
                return
            }
            DispatchQueue.main.async(execute: {
                
                // stop the loading animation
                self.activityIndicator.stopAnimating()
                switch session.status {
                    
                case .unknown:
                    
                    break
                case .waiting:
                    
                    break
                case .exporting:
                    
                    break
                case .completed:
                    
                    print(videoURL)
                    print(urlToBeCompressed)
                    print(newUrl)
                    
                    let fileSizeBefore = self.fileSize(forURL: urlToBeCompressed)
                    let fileSizeBeforeCompress = Double(round(10000 * fileSizeBefore) / 10000)
                    let strJS = "document.getElementById('OrginalVideoSize').innerHTML ='File before compression: '+ '\(fileSizeBeforeCompress)'+'mb';"
                    let showSize="document.getElementById('OrginalVideoSize').style.display = 'block';"
                    self.webView.evaluateJavaScript(showSize, completionHandler: nil)
                    self.webView.evaluateJavaScript(strJS, completionHandler: nil)
                    
                    print("File size before compression: \(fileSizeBeforeCompress) mb")
                    
                    let fileSizeAfter = self.fileSize(forURL: newUrl)
                    let fileSizeAfterCompress = Double(round(10000 * fileSizeAfter) / 10000)
                    print("File size after compression: \(fileSizeAfterCompress) mb")
                    print(newUrl)
                    let strJS1="var videoSrc = document.getElementById('video');"
                    let strJS2 = "videoSrc.src = '\(newUrl)';"
                    let strJs3=" videoSrc.play();"
                    let show="document.getElementById('video').style.display = 'block';"
                    self.webView.evaluateJavaScript(show, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    self.webView.evaluateJavaScript(strJS1, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    self.webView.evaluateJavaScript(strJS2, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    self.webView.evaluateJavaScript(strJs3, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    
                    
                    // save compressed video now
                    let extent = newUrl.pathExtension.lowercased()
                    self.saveMediaFileToAlbum(pathExtension: extent,outputURL: newUrl){(error) in
                        print(error as Any)
                        print("download video from app to album")
                    }

                    let sizeAfter = "document.getElementById('CompressedVideoSize').innerHTML ='File after compression: '+ '\(fileSizeAfterCompress)'+'mb';"
                    let showSizeAfter="document.getElementById('CompressedVideoSize').style.display = 'block';"
                    self.webView.evaluateJavaScript(showSizeAfter, completionHandler: nil)
                    self.webView.evaluateJavaScript(sizeAfter, completionHandler: nil)
                    

                    
                    //If app cannot compress, continue upload
                    
                case .failed:
                    self.dismiss(animated: false, completion: nil)
                    print("Failed to Compress")
                    
                    let strJS1="var videoSrc = document.getElementById('video');"
                    let strJS2 = "videoSrc.src = '\(urlToBeCompressed)';"
                    let strJs3=" videoSrc.play();"
                    let show="document.getElementById('video').style.display = 'block';"
                    self.webView.evaluateJavaScript(show, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    self.webView.evaluateJavaScript(strJS1, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    self.webView.evaluateJavaScript(strJS2, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    self.webView.evaluateJavaScript(strJs3, completionHandler: { (object, error) in
                        print(error as Any)
                    })
                    
                    // save non-compressed video now
                    let extent = urlToBeCompressed.pathExtension.lowercased()
                    
                    self.saveMediaFileToAlbum(pathExtension: extent,outputURL: urlToBeCompressed){(error) in
                        print(error as Any)
                        print("download non-compressed video from app to album")
                    }
                    
                    
                    let compressFail = "document.getElementById('CompressedVideoSize').innerHTML ='File fail to compressed';"
                    let showMessage="document.getElementById('CompressedVideoSize').style.display = 'block';"
                    
                    self.webView.evaluateJavaScript(showMessage, completionHandler: nil)
                    self.webView.evaluateJavaScript(compressFail, completionHandler: nil)
                    
                    
                    print(videoURL)
                    print(urlToBeCompressed)
                    print(newUrl)
                    break
                    
                case .cancelled:
                    break
                @unknown default:
                    self.dismiss(animated: false, completion: nil)
                    
                    print("unknown error")
                    fatalError()
                    
                    
                }
            })
            
        }
        
    }
    
    // Upload photo to local html
    func uploadImage(imageURL:URL){
        hiddenVideo()
        print("upload image now")
        let extent = imageURL.pathExtension.lowercased()
        // saved photo now
        saveMediaFileToAlbum(pathExtension: extent,outputURL: imageURL){(error) in
            print(error as Any)
            print("download image from app to album")
        }
        
        
        let strJS = "document.getElementById('myImg').src = '\(imageURL)';"
        let show="document.getElementById('myImg').style.display = 'block';"
        self.webView.evaluateJavaScript(show, completionHandler: { (object, error) in
            print(error as Any)
        })
        self.webView.evaluateJavaScript(strJS, completionHandler: { (object, error) in
            print(error as Any)
        })
        print("image url is \(imageURL)")
        let ImageSize = self.fileSize(forURL: imageURL)
        let showSize = "document.getElementById('ImageSize').innerHTML ='File size: '+ '\(ImageSize)'+'mb';"
        let SizeDisplay="document.getElementById('ImageSize').style.display = 'block';"
        self.webView.evaluateJavaScript(SizeDisplay, completionHandler: nil)
        self.webView.evaluateJavaScript(showSize, completionHandler: nil)
        
    }
    

    
    // check the file size according to the url
    func fileSize(forURL url: Any) -> Double {
        var fileURL: URL?
        var fileSize: Double = 0.0
        if (url is URL) || (url is String)
        {
            if (url is URL) {
                fileURL = url as? URL
            }
            else {
                fileURL = URL(fileURLWithPath: url as! String)
            }
            var fileSizeValue = 0.0
            try? fileSizeValue = (fileURL?.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
            if fileSizeValue > 0.0 {
                fileSize = (Double(fileSizeValue) / (1024 * 1024))
            }
        }
        return fileSize
    }
    
    // Compress video to low quality
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        
        
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        DispatchQueue.main.async(execute: {
            
            
            self.activityIndicator.startAnimating()
        })
        
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetLowQuality) else {
            handler(nil)
            
            activityIndicator.stopAnimating()
            print(Error.self)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            handler(exportSession)
            
        }
        
    }
    
    // loading animation
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style:.large)
        activityIndicator.color = UIColor.red
        activityIndicator.center = self.view.center
        return activityIndicator
    }()
   
    
    // Run loacl html
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "derp")
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true;
        config.userContentController = contentController
        
        
        webView = WKWebView(frame: self.view.frame, configuration: config)
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        self.view.addSubview(webView)
        
        let htmlpath=Bundle.main.path(forResource: "form", ofType: "html")
        let myURL = URL(fileURLWithPath:htmlpath!)
        let myRequest = URLRequest(url: myURL)
        webView.loadFileURL(myURL, allowingReadAccessTo: myURL)
        webView.navigationDelegate = self
        webView.load(myRequest)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.90).isActive = true
        
        // Run the loading animation
        self.view.addSubview(activityIndicator)
        
        
    }
    
}




