//
//  TripLogTableViewDataSource.swift
//  spectrum_tracker
//
//  Created by Admin on 6/27/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit

final class TripLogTableViewDataSource: NSObject, UITableViewDataSource {
    private let cellIdentifier = "tripLogCell"
    fileprivate var items: [ReplayTripLogModel] = []
    fileprivate var indexPaths: Set<IndexPath> = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! TripLogTableViewCell
        
        let header = self[indexPath].header
        let range = self[indexPath].range
        let detail = self[indexPath].detail
        let state = self[indexPath].state
        let maxSpeed = self[indexPath].maxSpeed
        cell.update(
            header: header,
            range: range,
            detail: detail,
            state: state,
            maxSpeed: maxSpeed
        )
        return cell
    }
    
    func getHeight() -> CGFloat {
        return CGFloat(270 * indexPaths.count + 50 * (items.count - indexPaths.count))
    }
}

extension TripLogTableViewDataSource {
   
    
    func insertData(_ replayTripLogModel: ReplayTripLogModel) {
        items.append(replayTripLogModel)
    }
    
    func dataClear() {
        items.removeAll()
    }
    
    func count() -> Int{
        return items.count
    }
}

extension TripLogTableViewDataSource {
    subscript(indexPath: IndexPath) -> ReplayTripLogModel {
        return items[indexPath.row]
    }
}
