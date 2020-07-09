//
//  ViewController.swift
//  WKRCloudStats
//
//  Created by Andrew Finke on 10/11/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Cocoa
import CloudKit

class ViewController: NSViewController {

    // MARK: - Properties -

    @IBOutlet var textView: NSTextView!

    var raceRecords = [CKRecord]()
    var playerRecords = [CKRecord]()
    let publicDB = CKContainer(identifier: "iCloud.com.andrewfinke.wikiraces").publicCloudDatabase

    var isUsingUserStatsV3 = true

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textColor = NSColor.labelColor
    }

    @IBAction func downloadPlayerStats(_ sender: Any) {
        playerRecords = []
        queryPlayerStats()
    }

    @IBAction func downloadRaceStats(_ sender: Any) {
        raceRecords = []
        queryRaceStats()
    }

}
