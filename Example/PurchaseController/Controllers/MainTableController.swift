//
//  MainTableController.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import UIKit

class MainTableController: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let sections: [SectionTableItemModel] = [.action, .purchases]
    
    weak var delegate: MainViewControllerPresentable?
    
    init(presentableDelegate: MainViewControllerPresentable) {
        self.delegate = presentableDelegate
        super.init()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        return section.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].rawValue
    }
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleItem(sections[indexPath.section].items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func handleItem(_ item: TableItemModel) {
        let _ = delegate?.perform(item.action, with: nil)
    }
}
