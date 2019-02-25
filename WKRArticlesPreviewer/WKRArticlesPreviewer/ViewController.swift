//
//  ViewController.swift
//  WKRArticlesPreviewer
//
//  Created by Andrew Finke on 2/24/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController {

    // MARK: - Properties

    @IBOutlet weak var webView: WKWebView!
    var selectButton: NSButton?

    var remainingArticles = [String]()
    var keepArticles = [String]()
    var removeArticles = [String]()

    var lastArticle = ""

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: URL(string: "https://en.m.wikipedia.org")!))
        NSWorkspace.shared.openFile(NSTemporaryDirectory())
    }

    func moveToNextArticle(keepCurrent: Bool) {
        let article = remainingArticles.removeFirst()
        lastArticle = article
        if keepCurrent {
            keepArticles.append(article)
        } else {
            removeArticles.append(article)
        }
        save(keepArticles, named: "keep")
        save(removeArticles, named: "remove")
        showNextArticle()
    }

    func save(_ array: [String], named name: String) {
        let path = NSTemporaryDirectory() + name + ".plist"
        NSMutableArray(array: array).write(toFile: path, atomically: false)
    }

    func showNextArticle() {
        let article = remainingArticles.first ?? ""
        guard let url = URL(string: "https://en.m.wikipedia.org/wiki" + article) else { fatalError() }
        webView.load(URLRequest(url: url))
        selectButton?.title = remainingArticles.count.description
    }

    // MARK: - Actions

    @IBAction func selectArticlesList(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title = "Choose articles file"
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = ["plist"]

        if dialog.runModal() == .OK, let result = dialog.url {
            guard let plist = NSArray(contentsOf: result) as? [String] else {
                fatalError()
            }
            remainingArticles = plist.sorted()
            showNextArticle()
        }
        selectButton = sender
    }

    @IBAction func keepArticle(_ sender: Any) {
        moveToNextArticle(keepCurrent: true)
    }

    @IBAction func removeArticle(_ sender: Any) {
        moveToNextArticle(keepCurrent: false)
    }

    @IBAction func undoLastAction(_ sender: Any) {
        if keepArticles.last == lastArticle {
            keepArticles.removeLast()
        } else if removeArticles.last == lastArticle {
            removeArticles.removeLast()
        }
        remainingArticles.insert(lastArticle, at: 0)
        showNextArticle()
    }

}

