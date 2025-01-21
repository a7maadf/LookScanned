

import UIKit
import PDFKit


class HandleUploadedFileVC: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var mainStackHeight: NSLayoutConstraint!
    @IBOutlet weak var mainStackWidth: NSLayoutConstraint!
    
    
    //    @IBOutlet weak var SliderWidthUI: NSLayoutConstraint!
    
    
    
    
    @IBOutlet weak var documentFirstPageImageView: UIImageView!
    
    
    @IBOutlet weak var downloadButton: UIButton!
    
    
    var isAccessingSecurityScopedResource = false
    var pdfURL: URL?
    var BlurValue: Float = 0.3
    var VarianceValueX: Float = 0.5
    var VarianceValueY: Float = 0.005
    var grayScale: Bool = true
    var roationActivated: Bool = false
    var addWatermarkActivated: Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        //        let screenSize: CGRect = UIScreen.main.bounds
        //        mainStackHeight.constant = screenSize.height * 0.85
        //        mainStackWidth.constant = screenSize.width * 0.85
        
        
        guard let pdfURL = pdfURL else {
            print("Error: pdfURL is nil.")
            return
        }
        
        // comment
        
        if pdfURL.startAccessingSecurityScopedResource() {
            isAccessingSecurityScopedResource = true
            defer { pdfURL.stopAccessingSecurityScopedResource() } // Added for safety
            if let image = convertPDFPageToImage(url: pdfURL, pageNumber: 1) {
                documentFirstPageImageView.image = makeImageLookScanned(image: image)
            } else {
                print("Error: Could not convert PDF page to image.")
            }
        } else {
            print("Error: Unable to access security-scoped resource.")
        }
        
        //        SliderWidthUI.constant = screenSize.width * 0.65
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop accessing the resource if it’s still being accessed
        if isAccessingSecurityScopedResource, let pdfURL = pdfURL {
            pdfURL.stopAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = false
        }
    }
    
    
    // Function to make an image look scanned
    func makeImageLookScanned(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // 1. Convert to grayscale (black and white)
        var grayscaleImage: CIImage // Declare the variable outside the if-else blocks
        
        if grayScale != false {
            guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
            grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
            guard let outputImage = grayscaleFilter.outputImage else { return nil }
            grayscaleImage = outputImage // Assign the output to the declared variable
        } else {
            grayscaleImage = ciImage // Assign ciImage to the declared variable
        }
        
        // 2. Apply a very subtle blur
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
        blurFilter.setValue(grayscaleImage, forKey: kCIInputImageKey)
        blurFilter.setValue(BlurValue, forKey: kCIInputRadiusKey) // Reduced blur for sharpness
        guard let blurredImage = blurFilter.outputImage else { return nil }
        
        
        // 3. Add small noise
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else { return nil }
        guard let noiseImage = noiseFilter.outputImage else { return nil }
        
        // Scale down the noise intensity
        let noiseTransform = CGAffineTransform(scaleX: CGFloat(VarianceValueX), y: CGFloat(VarianceValueY)) // Adjust noise size
        let scaledNoise = noiseImage.transformed(by: noiseTransform)
        
        // Blend noise with the image
        guard let blendFilter = CIFilter(name: "CIMultiplyCompositing") else { return nil }
        blendFilter.setValue(scaledNoise, forKey: kCIInputImageKey)
        blendFilter.setValue(blurredImage, forKey: kCIInputBackgroundImageKey)
        guard let noisyImage = blendFilter.outputImage else { return nil }
        
        // 4. Apply a very slight rotation
        var rotatedImage = noisyImage
        if roationActivated == true {
            let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.random(in: -0.03...0.03)) // Subtle rotation
            rotatedImage = noisyImage.transformed(by: rotationTransform)
        }
        
        
        // Render the final image
        if let outputCGImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) {
            return UIImage(cgImage: outputCGImage)
        }
        
        return nil
    }
    
    
    // Function that converts a PDF page to Image
    func convertPDFPageToImage(url: URL, pageNumber: Int) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        
        // Ensure the requested page number is valid
        guard pageNumber > 0 && pageNumber <= document.numberOfPages else { return nil }
        
        guard let page = document.page(at: pageNumber) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            ctx.cgContext.drawPDFPage(page)
        }
        
        return img
    }
    
    
    func refreshPreviewImage() {
        // Safely unwrap `pdfURL`
        guard let pdfURL = pdfURL else {
            print("Error: pdfURL is nil")
            return
        }
        
        // Access the security-scoped resource
        if pdfURL.startAccessingSecurityScopedResource() {
            defer { pdfURL.stopAccessingSecurityScopedResource() }
            
            // Attempt to get the first page image
            guard let firstPageImage = convertPDFPageToImage(url: pdfURL, pageNumber: 1) else {
                print("Error: Failed to convert PDF page to image")
                return
            }
            
            // Attempt to process the image
            guard let updatedImage = makeImageLookScanned(image: firstPageImage) else {
                print("Error: Failed to process image with makeImageLookScanned")
                return
            }
            
            // Update the UI
            documentFirstPageImageView.image = updatedImage
        } else {
            print("Error: Unable to access security-scoped resource")
        }
        
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.5) -> UIImage? {
        guard let jpegData = image.jpegData(compressionQuality: quality) else {
            print("Error: Could not compress image.")
            return nil
        }
        return UIImage(data: jpegData)
    }
    
    func processAndCompilePDF(pdfURL: URL, outputURL: URL) -> URL? {
        guard let document = CGPDFDocument(pdfURL as CFURL) else {
            print("Failed to load PDF document at \(pdfURL).")
            return nil
        }
        
        let numberOfPages = document.numberOfPages
        
        // Define the PDF renderer with a standard A4 page size
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 size in points
        
        do {
            try pdfRenderer.writePDF(to: outputURL) { context in
                for pageNumber in 1...numberOfPages {
                    // Convert each page to an image and apply scan effect using the existing function
                    if let image = makeImageLookScanned(image: convertPDFPageToImage(url: pdfURL, pageNumber: pageNumber)!) {
                        if let compressedImage = compressImage(image, quality: 0.5) {
                            context.beginPage()
                            compressedImage.draw(in: CGRect(x: 0, y: 0, width: 595, height: 842))
                            
                            if addWatermarkActivated {
                                // Add footer text to the bottom-right corner
                                let footerText = "Scanned by CamScanner"
                                let attributes: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.systemFont(ofSize: 10),
                                    .foregroundColor: UIColor.black
                                ]
                                let textSize = footerText.size(withAttributes: attributes)
                                let footerX = 595 - textSize.width - 20 // 20-point margin from the right edge
                                let footerY = 842 - textSize.height - 20 // 20-point margin from the bottom edge
                                footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: attributes)
                            }
                            
                            
                            print("Successfully added page \(pageNumber) to the new PDF.")
                        } else {
                            print("Failed to compress page \(pageNumber). Skipping.")
                        }
                    } else {
                        print("Failed to process page \(pageNumber). Skipping.")
                    }
                }
            }
            print("Compiled PDF successfully saved at \(outputURL.path).")
            
            return outputURL
        } catch {
            print("Failed to create compiled PDF: \(error)")
            return nil
        }
    }
    
    
    func downloadRequested(url: URL, viewController: UIViewController) {
        let inputPDFURL = url
        
        // Get the path to the app's Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputPDFURL = documentsDirectory.appendingPathComponent("output.pdf")
        
        // Ensure the URL is valid and accessible
        if !url.startAccessingSecurityScopedResource() {
            print("Error: Unable to access security-scoped resource for download.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        
        if let compiledPDF = processAndCompilePDF(pdfURL: inputPDFURL, outputURL: outputPDFURL) {
            print("Compiled PDF created at: \(compiledPDF.path)")
            
            let activityViewController = UIActivityViewController(activityItems: [compiledPDF], applicationActivities: nil)
            
            
            // Configure the popover for iPad
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = viewController.view // Anchor the popover to the main view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0) // Center the popover
                popoverController.permittedArrowDirections = [] // Disable the arrow
            }
            
            // Ensure presentation happens on the main thread
            DispatchQueue.main.async {
                viewController.present(activityViewController, animated: true) {
                    print("Share menu presented for file: \(compiledPDF.path)")
                }
            }
        } else {
            print("Failed to create compiled PDF.")
        }
    }
    
    @IBAction func downloadButtonPressed(_ sender: UIButton) {
        
        
        // Disable the button and update the title
        downloadButton.isEnabled = false
        downloadButton.setTitle("Loading...", for: .normal)
        
        // Perform the download in the background to avoid blocking the main thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Perform the download
            self.downloadRequested(url: self.pdfURL!, viewController: self)
            
            // Once the download is complete, update the UI on the main thread
            DispatchQueue.main.async {
                self.downloadButton.setTitle("Export", for: .normal)
                self.downloadButton.isEnabled = true
                self.isModalInPresentation = false
            }
        }
        
        
    }
    
    
    @IBAction func blurnessSlider(_ sender: UISlider) {
        BlurValue = sender.value
        
        refreshPreviewImage()
    }
    
    @IBAction func varianceSliderX(_ sender: UISlider) {
        VarianceValueX = sender.value
        
        refreshPreviewImage()
    }
    //
    
    @IBAction func varianceSliderY(_ sender: UISlider) {
        VarianceValueY = sender.value
        
        refreshPreviewImage()
    }
    
    
    
    @IBAction func backToATapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goBackHome", sender: self)
    }
    
    
    @IBAction func grayScaleToggle(_ sender: UISwitch) {
        grayScale = !grayScale
        
        refreshPreviewImage()
    }
    
    
    @IBAction func rotationToggle(_ sender: UISwitch) {
        roationActivated = !roationActivated
        
        refreshPreviewImage()
    }
    
    
    @IBAction func csmscannerwatermarktoggle(_ sender: UISwitch) {
        addWatermarkActivated = !addWatermarkActivated
    }
    
    
    
}
