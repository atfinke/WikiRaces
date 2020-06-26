//
//  ShareCodeView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct ShareCodeView: UIViewControllerRepresentable {
    
    let raceCode: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareCodeView>) -> UIActivityViewController {
        guard let url = URL(string: "wikiraces://invite?code=\(raceCode)") else {
            fatalError()
        }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: [])
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareCodeView>) {}
    
}
