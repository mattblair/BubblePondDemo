//
//  ThemesViewController.swift
//  BubblePond
//
//  Created by Matt Blair on 5/11/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import UIKit


struct Theme: Codable {
    let title: String
    let notes: String?
    let filename: String
    let backgroundImage: String?
    let iconImage: String?
}


protocol ThemesViewControllerDelegate: AnyObject {
    func themeViewController(_ themeVC: ThemesViewController,
                             didSelect theme: Theme)
}


class ThemesViewController: UITableViewController {

    // Note: since the theme list doesn't contain theme details, just load it in VC
    var themeList = [Theme]()
    var selectedThemeIndex = 0
    
    let cellReuseID = "reuseIdentifier"
    
    weak var delegate: ThemesViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseID)
        
        loadThemes()
    }
    
    func loadThemes() {
        
        if let themeListPath = Bundle.main.path(forResource: "themelist",
                                               ofType: "json") {
            
            do {
                let themeListJSONString = try String(contentsOfFile: themeListPath)
                if let jsonData = themeListJSONString.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    
                    themeList = try decoder.decode(Array<Theme>.self, from: jsonData)
                    print(themeList as Any)
                    
                } else {
                    print("Failed to convert theme list JSON data into a string.")
                }
            } catch {
                print("Failed to parse playlist: \(error)")
            }
        } else {
            print("Couldn't find playlist json file")
        }
    }
    
    
    // MARK: - UITableViewDataSource Protocol

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return themeList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseID,
                                                 for: indexPath)

        cell.textLabel?.text = themeList[indexPath.item].title

        return cell
    }

    
    // MARK: - UITableViewDelegate Protocol
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Is this needed?
        selectedThemeIndex = indexPath.item
        
        delegate?.themeViewController(self, didSelect: themeList[selectedThemeIndex])
        
        presentingViewController?.dismiss(animated: true)
    }
}
