//
//  ScoreEditorViewController.swift
//  BubblePond
//
//  Created by Matt Blair on 5/10/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import UIKit

protocol ScoreEditorViewControllerDelegate: AnyObject {
    
    func scoreEditor(_: ScoreEditorViewController, finishedWith editedScore: BubblePondScore)
}


class ScoreEditorViewController: UIViewController {
    
    var score: BubblePondScore?
    
    weak var delegate: ScoreEditorViewControllerDelegate?
    
    var cancelButton: UIBarButtonItem?
    var updateButton: UIBarButtonItem?
    // swiftlint:disable:next implicitly_unwrapped_optional
    var scoreEditView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scoreEditView = UITextView(frame: view.frame)
        scoreEditView.isEditable = true
        scoreEditView.font = UIFont.systemFont(ofSize: 16.0)
        view.addSubview(scoreEditView)
        
        if let scoreStruct = score {
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let scoreData = try encoder.encode(scoreStruct)
                let scoreString = String(data: scoreData, encoding: .utf8)
                scoreEditView.text = scoreString
            } catch {
                print("Unable to encode score as string: \(error)")
            }
        }
        
        cancelButton = UIBarButtonItem(title: "Cancel",
                                       style: .plain,
                                       target: self,
                                       action: #selector(cancelEdits))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        updateButton = UIBarButtonItem(title: "Update",
                                       style: .plain,
                                       target: self,
                                       action: #selector(validateAndUpdate))
        self.navigationItem.rightBarButtonItem = updateButton
        
        // TODO: Add save button to nav
    }
    
    
    // MARK: - Cancel and Update
    
    @objc
    func cancelEdits() {
        
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc
    func validateAndUpdate() {
        
        // TODO: post an error for this case
        guard let scoreJSONString = scoreEditView.text else { return }
        
        print("Text is: \(scoreJSONString)")
        
        var errorMessage: String?
        
        do {
            if let jsonData = scoreJSONString.data(using: .utf8) {
                let decoder = JSONDecoder()
                
                let bpScore = try decoder.decode(BubblePondScore.self,
                                                 from: jsonData)
                
                delegate?.scoreEditor(self, finishedWith: bpScore)
                presentingViewController?.dismiss(animated: true)
            } else {
                errorMessage = "Failed convert score text to data."
            }
        } catch {
            errorMessage = "Failed to parse score text: \(error)"
        }
        
        if let message = errorMessage {
            showError(message: message)
        }
    }
    
    func showError(message: String) {
        let ac = UIAlertController(title: "Error",
                                   message: message,
                                   preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        ac.addAction(okAction)
        
        present(ac, animated: true, completion: nil)
    }
}
