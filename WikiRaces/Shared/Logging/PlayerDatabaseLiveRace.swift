//
//  PlayerDatabaseLiveRace.swift
//  WikiRaces
//
//  Created by Andrew Finke on 7/1/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import CloudKit
import WKRKit
import os.log

class PlayerDatabaseLiveRace {
    
    // MARK: - Types -
    
    enum RaceCodeResult {
        case valid, invalid, noiCloudAccount
    }
    
    // MARK: - Properties -
    
    static var shared = PlayerDatabaseLiveRace()
    
    private let writeQueue = DispatchQueue(label: "com.andrewfinke.WikiRaces", qos: .utility)
    private let encoder = JSONEncoder()
    
    private var activeRecord: CKRecord?
    private var activeRaceCode: String?
    
    private var queuedResultsInfo: WKRResultsInfo?
    
    func reset() {
        activeRecord = nil
        activeRaceCode = nil
        queuedResultsInfo = nil
    }
    
    func updated(resultsInfo: WKRResultsInfo) {
        writeQueue.async {
            var adjusted = resultsInfo
            adjusted.minimize()
            self.queuedResultsInfo = adjusted
            os_log("%{public}s: queued results", log: .raceLiveDatabase, type: .info, #function)
        }
        writeQueue.asyncAfter(deadline: .now() + 5) {
            os_log("%{public}s: async check started", log: .raceLiveDatabase, type: .info, #function)
            guard let resultsInfo = self.queuedResultsInfo,
                let data = try? self.encoder.encode(resultsInfo),
                let url = self.write(data: data, suffix: "WKRResultsInfo"),
                let record = self.activeRecord else {
                    os_log("%{public}s: async check exit early", log: .raceLiveDatabase, type: .info, #function)
                return
            }
            self.queuedResultsInfo = nil
            record["ResultsInfo"] = CKAsset(fileURL: url)
            
            os_log("%{public}s: async check completed", log: .raceLiveDatabase, type: .info, #function)
            self.save(record: record)
        }
    }
    
    func updated(state: WKRGameState) {
        guard let record = activeRecord else { return }
        record["State"] = state.rawValue
        save(record: record)
    }
    
    func save(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if let error = error {
                os_log("%{public}s: error: %{public}s", log: .raceLiveDatabase, type: .error, #function, error.localizedDescription)
            } else {
                os_log("%{public}s: successful", log: .raceLiveDatabase, type: .info, #function)
            }
        }
    }
    
    private func write(data: Data, suffix: String) -> URL? {
        os_log("%{public}s", log: .raceLiveDatabase, type: .info, #function)
        
        guard let code = activeRaceCode,
            let filePath = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .last?
                .path
                .appendingFormat("/\(code)-\(suffix).data") else {
                    return nil
        }
        
        os_log("%{public}s: writing to %{public}s (size: %{public}ld)", log: .raceLiveDatabase, type: .info, #function, filePath, data.count)
        let filePathURL = URL(fileURLWithPath: filePath)
        
        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            try data.write(to: filePathURL)
        } catch {
            os_log("%{public}s: write error: %{public}s", log: .raceLiveDatabase, type: .error, #function, error.localizedDescription)
            return nil
        }
        return filePathURL
    }

    func isCloudEnabled(completion: @escaping ((Bool) -> Void)) {
         CKContainer.default().accountStatus { status, _ in
            os_log("%{public}s: status: %{public}ld", log: .raceLiveDatabase, type: .info, #function, status.rawValue)
            completion(status == .available)
        }
    }
    
    func isRaceCodeValid(raceCode: String, host: String, completion: @escaping ((RaceCodeResult) -> Void)) {
        os_log("%{public}s: %{public}s", log: .raceLiveDatabase, type: .info, #function, raceCode)
        
        isCloudEnabled { isEnabled in
            if isEnabled {
                self.fetchValidRecord(for: raceCode) { record, isRaceCodeValid in
                    if isRaceCodeValid {
                        if record != nil {
                            PlayerAnonymousMetrics.log(event: .revampRaceCodeRecordCreated)
                        }
                        let raceRecord = record ?? CKRecord(recordType: "RaceActive")
                        self.claim(record: raceRecord, raceCode: raceCode, host: host)
                        completion(.valid)
                    } else {
                        completion(.invalid)
                    }
                }
            } else {
                completion(.noiCloudAccount)
            }
        }
    }
    
    private func fetchValidRecord(for raceCode: String, completion: @escaping ((CKRecord?, Bool) -> Void)) {
        let predicate = NSPredicate(format: "Code == %@", raceCode)
        let sort = NSSortDescriptor(key: "modificationDate", ascending: false)
        let query = CKQuery(recordType: "RaceActive", predicate: predicate)
        query.sortDescriptors = [sort]
        
        var isRaceCodeValid = true
        var existingRecord: CKRecord?
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.recordFetchedBlock = { record in
            if let date = record.modificationDate {
                existingRecord = record
                
                let timeIntervalSinceNow = -Int(date.timeIntervalSinceNow)
                if timeIntervalSinceNow < WKRKitConstants.current.raceCodeRecordMinReuseTimeSinceNow {
                    isRaceCodeValid = false
                    PlayerAnonymousMetrics.log(event: .revampRaceCodeRecordTooRecent)
                    os_log("%{public}s: existing record too new: %{public}ld, min is  %{public}ld", log: .raceLiveDatabase, type: .info, #function, timeIntervalSinceNow, WKRKitConstants.current.raceCodeRecordMinReuseTimeSinceNow)
                } else {
                    os_log("%{public}s: existing record is reusable: %{public}ld, min is  %{public}ld", log: .raceLiveDatabase, type: .info, #function, timeIntervalSinceNow, WKRKitConstants.current.raceCodeRecordMinReuseTimeSinceNow)
                }
            } else {
                isRaceCodeValid = false
                PlayerAnonymousMetrics.log(event: .revampRaceCodeRecordTooRecent)
                os_log("%{public}s: existing record has no date", log: .raceLiveDatabase, type: .error, #function)
            }
        }
        
        operation.completionBlock = {
            if isRaceCodeValid {
                os_log("%{public}s: valid race code", log: .raceLiveDatabase, type: .info, #function)
                completion(existingRecord, true)
            } else {
                os_log("%{public}s: invalid race code", log: .raceLiveDatabase, type: .info, #function)
                completion(nil, false)
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    private func claim(record: CKRecord, raceCode: String, host: String) {
        os_log("%{public}s", log: .raceLiveDatabase, type: .info, #function)
        record["Code"] = raceCode
        record["Version"] = 1
        record["Host"] = host
        activeRaceCode = raceCode
        activeRecord = record
        save(record: record)
    }
    
}

