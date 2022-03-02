//
//  TableDataPersistanceService.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 02.03.2022..
//

import Foundation

final class TableDataPersistanceService {
    private let userDefaults = UserDefaults.standard
    private let tableDataDefaultsKey = "tableData"
    
    func saveTableData(_ tableData: [String]) {
        guard let data = try? JSONEncoder().encode(tableData) else {
            print("Filed to convert [String] to Data")
            return
        }
        userDefaults.set(data, forKey: tableDataDefaultsKey)
    }
    
    func getTableData() -> [String] {
        guard
        let data = userDefaults.data(forKey: tableDataDefaultsKey),
        let array = try? JSONDecoder().decode([String].self, from: data) else {
            print("Filed to convert Data to [String]")
            return []
        }
        return array
    }
}

