//
//  ReportTableViewCell.swift
//  spectrum_tracker
//
//  Created by Admin on 6/13/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit
import Charts
class BarChartFormatter: NSObject, IAxisValueFormatter {
    
    var labels: [String] = []
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        if index < labels.count && index >= 0 {
            return labels[index]
        } else {
            return ""
        }
    }
    
    init(labels: [String]) {
        super.init()
        self.labels = labels
    }
}
class BarChartValueFormatter: NSObject, IValueFormatter {
    
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        if flag == 0 {
            return String(format: "%.2f",value)
        }
        else {
            return String(Int(value))
        }
    }
    
    var flag: Int = 0
    
    init(flag: Int) {
        super.init()
        self.flag = flag
    }
}
class ReportTableViewCell: UITableViewCell {
    enum CellState {
        case collapsed
        case expanded
        
        var carretImage: UIImage {
            switch self {
            case .collapsed:
                return #imageLiteral(resourceName: "expand")
            case .expanded:
                return #imageLiteral(resourceName: "collapse")
            }
        }
    }
    var state: CellState = .collapsed {
        didSet {
            toggle()
        }
    }
    var flag: Bool = true
    private let expandedViewIndex: Int = 1
    @IBOutlet var divide_line: UIImageView!
    @IBOutlet var ic_arrow: UIImageView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var label_title: UILabel!
    @IBOutlet var label_value: UILabel!
    @IBOutlet var reportEventTableView: ReportEventTableView!
    @IBOutlet var barchartview: BarChartView!
    @IBOutlet weak var valueLabelWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    private func toggle() {
        if(flag){
            stackView.arrangedSubviews[expandedViewIndex].isHidden = stateIsCollapsed()
            ic_arrow.image = state.carretImage
        }
    }
    
    private func stateIsCollapsed() -> Bool {
        return state == .collapsed
    }
    
    func update(title: String, value: String, chartValue: [ReportChartModel], valueFormatter: Int, eventValue: [ReportEventModel]) {
        if eventValue.count > 0 {
            barchartview.isHidden = true
            reportEventTableView.isHidden = false
            reportEventTableView.setData(eventValue)
            reportEventTableView.reloadData()
        }
        else {
            barchartview.isHidden = false
            reportEventTableView.isHidden = true
        }
        label_title.text = title
        
        if title == "Distance" {
            let distanceUnit = Global.getDistanceUnit()
            label_value.text = value + " " + distanceUnit
            valueLabelWidthConstraint.constant = 80
            label_value.layer.cornerRadius = 22
        } else if title == "Max Speed" {
            let speedUnit = Global.getDistanceUnit() == "miles" ? "mph" : "kmh"
            label_value.text = value + " " + speedUnit
            valueLabelWidthConstraint.constant = 80
            label_value.layer.cornerRadius = 22
        } else {
            label_value.text = value
            valueLabelWidthConstraint.constant = 44
            label_value.layer.cornerRadius = 22
        }
        
        if (Double(value)?.isEqual(to: 0))! {
            flag = false
            stackView.arrangedSubviews[expandedViewIndex].isHidden = true
            ic_arrow.image = #imageLiteral(resourceName: "expand")
            print("value is 0")
        }
        else {
            flag = true
            print("value isn't 0")
        }
        var values: [BarChartDataEntry] = [BarChartDataEntry]()
        let weekdays: [String] = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        for w_index in 0..<7 {
            var flag: Bool = false
            for i in 0..<chartValue.count {
                let chart_data:ReportChartModel = chartValue[i]
                var week_day = chart_data.date.weekDay()
                if week_day == 1 {week_day += 7}
                if chart_data.value != 0.0 && w_index == week_day-2 {
                    values.append(BarChartDataEntry(x: Double(week_day-2), y:chart_data.value))
                    flag = true
                }
            }
            if !flag {
                values.append(BarChartDataEntry(x: Double(w_index), y:0))
            }
        }
        let set: BarChartDataSet = BarChartDataSet(values: values, label: title)
        set.valueFont = UIFont.systemFont(ofSize: 14.0)
        let data: BarChartData = BarChartData(dataSet: set)
        data.setValueFormatter(BarChartValueFormatter(flag: valueFormatter))
        barchartview.data = data
        barchartview.legend.font = UIFont.systemFont(ofSize: 13.0)
        barchartview.xAxis.labelPosition = XAxis.LabelPosition.bottom
        barchartview.xAxis.valueFormatter = BarChartFormatter(labels: weekdays)
        barchartview.notifyDataSetChanged()
        barchartview.chartDescription?.enabled = false
        barchartview.rightAxis.drawGridLinesEnabled = false
        barchartview.leftAxis.drawGridLinesEnabled = false
        barchartview.doubleTapToZoomEnabled = false
        barchartview.pinchZoomEnabled = false
        barchartview.setScaleEnabled(false)
        barchartview.highlightPerTapEnabled = false
        barchartview.highlightFullBarEnabled = false
        barchartview.dragEnabled = false
        barchartview.highlightPerDragEnabled = false
        barchartview.xAxis.drawGridLinesEnabled = false
        barchartview.xAxis.labelFont = UIFont.systemFont(ofSize: 14.0)
        barchartview.xAxis.labelTextColor = UIColor(red: 101, green: 38, blue: 152)
        barchartview.rightAxis.enabled = false
        barchartview.rightAxis.axisMinimum = 0
        barchartview.leftAxis.axisMinimum = 0
        barchartview.leftAxis.enabled = false
        barchartview.backgroundColor = UIColor(hexString: "#efeafb")
    }
    
}
