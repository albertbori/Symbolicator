//
//  ViewController.swift
//  Symbolicator
//
//  Created by Albert Bori on 1/5/17.
//  Copyright © 2017 Albert Bori. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var logFileLabel: NSTextField!
    @IBOutlet weak var logFileTextField: NSTextField!
    @IBOutlet weak var symbolsFileLabel: NSTextField!
    @IBOutlet weak var symbolsFileTextField: NSTextField!
    @IBOutlet weak var symbolicateButton: NSButton!
    @IBOutlet var resultTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        logFileTextField.stringValue = "/Users/albertbori/Desktop/Crash.log"
        symbolsFileTextField.stringValue = "/Users/albertbori/Library/Developer/Xcode/Archives/2017-01-04/Rushline QA 1-4-17, 2.26 PM.xcarchive"
        validatePaths()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func selectLogFile(_ sender: NSButton) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .log file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["log"];
        dialog.directoryURL            = URL(string: "~/Desktop")
        
        if (dialog.runModal() == NSModalResponseOK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                logFileTextField.stringValue = path
                validatePaths()
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    @IBAction func selectSymbolsFile(_ sender: NSButton) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .dSYM file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["dSYM", "xcarchive"];
        dialog.directoryURL            = URL(string: "~/Library/Developer/Xcode/Archives/")
        
        if (dialog.runModal() == NSModalResponseOK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                symbolsFileTextField.stringValue = path
                validatePaths()
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func symbolicate(_ sender: NSButton) {
        
        var dsymFile = symbolsFileTextField.stringValue
        
        //if it's an xcarchive, extract the dsym location
        if dsymFile.hasSuffix("xcarchive") {
             let plistPath = URL(fileURLWithPath: "\(dsymFile)/Info.plist")
            guard
                let plist = NSDictionary(contentsOf: plistPath),
                let applicationPath = (plist["ApplicationProperties"] as? NSDictionary)?["ApplicationPath"] as? String
            else {
                let myPopup: NSAlert = NSAlert()
                myPopup.messageText = "Error"
                myPopup.informativeText = "Unable to find dSYMs in xcarchive. The application name was unresolvable."
                myPopup.alertStyle = NSAlertStyle.warning
                myPopup.addButton(withTitle: "OK")
                myPopup.runModal()
                return
            }
            
            let regex = try! NSRegularExpression(pattern: "/(.*?).app$", options: [])
            let matches = regex.matches(in: applicationPath, options: [], range: NSRange(location: 0, length: applicationPath.characters.count))
            let applicationShortName = matches.first!
            
            //dsymFile = "\(dsymFile)/dSYMs"
            //dsymFile = "\(dsymFile)/dSYMs/\(applicationShortName).dSYM"
            dsymFile = "\(dsymFile)/\(applicationPath)"
        }
        
        
        let output = shell(launchPath: "/bin/sh", arguments: ["-c", "export DEVELOPER_DIR=\"/Applications/Xcode.app/Contents/Developer/\"; /Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash -v \"\(logFileTextField.stringValue)\" \"\(symbolsFileTextField.stringValue)\""])
        
        resultTextView.string = output
    }
    
    func validatePaths() {
        
        logFileTextField.textColor = NSColor.black
        symbolsFileTextField.textColor = NSColor.black
        
        var errorFound = false
        let fileManager = FileManager.default
        if logFileTextField.stringValue != "" && !fileManager.fileExists(atPath: logFileTextField.stringValue) {
            errorFound = true
            logFileTextField.textColor = NSColor.red
        }
        if symbolsFileTextField.stringValue != "" && !fileManager.fileExists(atPath: symbolsFileTextField.stringValue) {
            errorFound = true
            symbolsFileTextField.textColor = NSColor.red
        }
        
        if !errorFound && logFileTextField.stringValue != "" && symbolsFileTextField.stringValue != "" {
            symbolicateButton.isEnabled = true
        }
    }
    
    func shell(launchPath: String, arguments: [String]) -> String
    {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        return output
    }
}

