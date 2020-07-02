//
//  WKRRaceLiveRecord.swift
//  WKRRaceLiveViewer
//
//  Created by Andrew Finke on 7/2/20.
//

import CloudKit
import WKRKitCore

struct WKRRaceLiveRecord {

    // MARK: - Types -

    private enum Key: String {
        case version, state, host, code, resultsInfo
    }

    // MARK: - Properties -

    private let record: CKRecord

    // MARK: - Initalization -

    init(record: CKRecord) {
        self.record = record
    }

    // MARK: - Helpers -

    func state() -> WKRGameState? {
        guard let value = record[Key.state.rawValue.capitalized] as? Int else { return nil }
        return WKRGameState(rawValue: value)
    }

    func host() -> String? {
        guard let value = record[Key.host.rawValue.capitalized] as? String else { return nil }
        return value
    }

    func code() -> String? {
        guard let value = record[Key.code.rawValue.capitalized] as? String else { return nil }
        return value
    }

    func resultsInfo() -> WKRResultsInfo? {
        guard let value = record["ResultsInfo"] as? CKAsset,
              let url = value.fileURL,
              let data = try? Data(contentsOf: url),
              let object = try? JSONDecoder().decode(WKRResultsInfo.self, from: data) else { return nil }
        return object
    }
}
