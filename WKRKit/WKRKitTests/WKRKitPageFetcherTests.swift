//
//  WKRKitPageFetcherTests.swift
//  WKRKitTests
//
//  Created by Andrew Finke on 9/3/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest
@testable import WKRKit

class WKRKitPageFetcherTests: WKRKitTestCase {

    func testConnectionTester() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let testExpectation = expectation(description: "testConnectionTester")
            WKRConnectionTester.start { connected in
                XCTAssert(connected)
                testExpectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }

    func testError() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let testExpectation = expectation(description: "testError")
            WKRPageFetcher.fetch(path: "") { page in
                XCTAssertNil(page)
                testExpectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }

    func testRandom() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let testExpectation = expectation(description: "testRandom")
            WKRPageFetcher.fetchRandom { page in
                XCTAssertNotNil(page)
                guard let unwrappedPage = page else {
                    XCTFail("Page nil")
                    return
                }
                XCTAssertNotNil(unwrappedPage.title)
                guard let title = unwrappedPage.title else {
                    XCTFail("Title nil")
                    return
                }
                XCTAssert(!title.isEmpty)
                XCTAssert(unwrappedPage.url.absoluteString.contains("https://en.m.wikipedia.org/wiki/"))
                XCTAssertFalse(unwrappedPage.url.absoluteString.contains("Special:Random"))
                testExpectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }

    func testPage() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let testExpectation = expectation(description: "testPage")
            WKRPageFetcher.fetch(path: "/Apple_Inc.") { page in
                XCTAssertNotNil(page)
                guard let unwrappedPage = page else {
                    XCTFail("Page nil")
                    return
                }
                XCTAssertNotNil(unwrappedPage.title)
                guard let title = unwrappedPage.title else {
                    XCTFail("Title nil")
                    return
                }
                XCTAssertEqual(title, "Apple Inc.")
                XCTAssertEqual(unwrappedPage.url.absoluteString, "https://en.m.wikipedia.org/wiki/Apple_Inc.")
                testExpectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }

    func testURL() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let testExpectation = expectation(description: "testURL")
            WKRPageFetcher.fetch(url: URL(string: "https://en.m.wikipedia.org/wiki/Apple_Inc.")!) { page in
                XCTAssertNotNil(page)
                guard let unwrappedPage = page else {
                    XCTFail("Page nil")
                    return
                }
                XCTAssertNotNil(unwrappedPage.title)
                guard let title = unwrappedPage.title else {
                    XCTFail("Title nil")
                    return
                }
                XCTAssertEqual(title, "Apple Inc.")
                XCTAssertEqual(unwrappedPage.url.absoluteString, "https://en.m.wikipedia.org/wiki/Apple_Inc.")
                testExpectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }

    func testSource() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let testExpectation = expectation(description: "testSource")
            WKRPageFetcher.fetchSource(url: URL(string: "https://en.m.wikipedia.org/wiki/Apple_Inc.")!) { source in
                XCTAssertNotNil(source)
                testExpectation.fulfill()
            }
            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }

    func testLinkedPageFetcher() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = WKRLinkedPagesFetcher()
            let url = URL(string: "https://en.m.wikipedia.org/wiki/Positive_feedback")!
            fetcher.start(for: WKRPage(title: nil, url: url))

            let testExpectation = expectation(description: "testLinkedPageFetcher")

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                XCTAssertGreaterThan(fetcher.foundURLs.count, 200)
                XCTAssertLessThan(fetcher.foundURLs.count, 800)
                testExpectation.fulfill()
            }

            waitForExpectations(timeout: 10.0, handler: { _ in
                self.stopMeasuring()
            })
        }
    }
}
