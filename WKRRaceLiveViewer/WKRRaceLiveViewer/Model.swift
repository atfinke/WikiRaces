//
//  Model.swift
//  WKRRaceLiveViewer
//
//  Created by Andrew Finke on 7/2/20.
//

import CloudKit
import WKRKitCore

class Model: ObservableObject {

    // MARK: - Properties -

    private let raceCode: String

    @Published var host: String?
    @Published var state: WKRGameState?
    @Published var resultsInfo: WKRResultsInfo?

    // MARK: - Initalization -

    init(raceCode: String) {
        self.raceCode = raceCode
        update()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.update()
        }
    }

    // MARK: - Helpers -

    func update() {
        let predicate = NSPredicate(format: "Code == %@", raceCode)
        let sort = NSSortDescriptor(key: "modificationDate", ascending: false)
        let query = CKQuery(recordType: "RaceActive", predicate: predicate)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.recordFetchedBlock = { record in
            let wrapper = WKRRaceActiveRecordWrapper(record: record)
            DispatchQueue.main.async {
                self.host = wrapper.host()
                self.state = wrapper.state()
                self.resultsInfo = wrapper.resultsInfo()
            }
        }
        CKContainer(identifier: "iCloud.com.andrewfinke.wikiraces").publicCloudDatabase.add(operation)
    }

}
