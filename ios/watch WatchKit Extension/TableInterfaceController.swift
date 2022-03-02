//
//  TableInterfaceController.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 01.03.2022..
//

import Foundation
import WatchKit
import WatchConnectivity

final class TableInterfaceController: WKInterfaceController {
    @IBOutlet weak var table: WKInterfaceTable!
    var wcSession:  WCSession?
    private var tableData = [String]()
    private let tableDataPersistanceService = TableDataPersistanceService()
    private let communicationService = CommunicationService.instance

    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        communicationService.addDelegate(self)
        updateTable()
    }
    
    override func willDisappear() {
        communicationService.removeDelegate(withId: self.id)
    }
    
    func updateTable() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableData = self.tableDataPersistanceService.getTableData()
            let numberOfRows = self.tableData.count
            self.table.setNumberOfRows(numberOfRows, withRowType: "TableViewCell")
            for index in 0..<numberOfRows {
                guard let tableRow = self.table.rowController(at: index) as? TableViewCell else { return }
                tableRow.label.setText(self.tableData[index])
            }
        }
    }
}


extension TableInterfaceController: CommunicationServiceDelegate {
    var subscriptionTheme: WatchReceiveMethod {
        .presentTableData
    }
    
    var id: String {
            "tableId"
    }
    
    func onDataReceived(data: Any?) {
        updateTable()
    }
}
