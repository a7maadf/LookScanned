//
//  ViewController.swift
//  LookScanned
//
//  Created  on 1/11/25.
//

import UIKit

class ViewController: UIViewController, UIDocumentPickerDelegate {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPDFPage" {
            if let destinationVC = segue.destination as? HandleUploadedFileVC,
               let pdfURL = sender as? URL {
                destinationVC.pdfURL = pdfURL
            } else {
                print("Error: Could not cast sender to URL or destination to HandleUploadedFileVC.")
            }
        }
    }


    @IBAction func uploadButtonPressed(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("Error: No file selected.")
            return
        }

        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            print("Selected file URL: \(url)")
            performSegue(withIdentifier: "showPDFPage", sender: url)
        } else {
            print("Error: Unable to access security-scoped resource.")
        }
    }
    
}

