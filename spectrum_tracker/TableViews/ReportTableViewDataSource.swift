//
//  ReportTableViewDataSource.swift
//  spectrum_tracker
//
//  Created by Admin on 6/13/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit

final class ReportTableViewDataSource: NSObject, UITableViewDataSource {
    private let cellIdentifier = "reportCell"
    fileprivate var items: [ReportModel] = []
    fileprivate var indexPaths: Set<IndexPath> = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ReportTableViewCell
        
        let title = self[indexPath].title
        let value = self[indexPath].value
        let chartValue = self[indexPath].chartValue
        cell.update(
            title: title,
            value: value,
            chartValue: chartValue,
            valueFormatter: (indexPath.row > 2) ? 1 : 0,
            eventValue: self[indexPath].eventValue
        )
        if indexPath.row == 0 {cell.divide_line.isHidden = true}
        cell.state = cellIsExpanded(at: indexPath) ? .expanded : .collapsed
        return cell
    }
    
    func getHeight() -> CGFloat {
        return CGFloat(270 * indexPaths.count + 50 * (items.count - indexPaths.count))
    }
}

extension ReportTableViewDataSource {
    func cellIsExpanded(at indexPath: IndexPath) -> Bool {
        return indexPaths.contains(indexPath)
    }
    
    func addExpandedIndexPath(_ indexPath: IndexPath) {
        indexPaths.insert(indexPath)
    }
    
    func removeExpandedIndexPath(_ indexPath: IndexPath) {
        indexPaths.remove(indexPath)
    }
    
    func insertData(_ reportModel: ReportModel) {
        items.append(reportModel)
    }
    
    func dataClear() {
        items.removeAll()
    }
}

extension ReportTableViewDataSource {
    subscript(indexPath: IndexPath) -> ReportModel {
        return items[indexPath.row]
    }
}
