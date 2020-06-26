//
//  RaceSettingsView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct RaceSettingsView: UIViewControllerRepresentable {
    
    @ObservedObject var model: PrivateRaceContentViewModel
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<RaceSettingsView>) -> UINavigationController {
        let controller = CustomRaceViewController(settings: model.settings, pages: model.customPages) { pages in
            self.model.customPages = pages
        }
        return UINavigationController(rootViewController: controller)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<RaceSettingsView>) {}
    
}
