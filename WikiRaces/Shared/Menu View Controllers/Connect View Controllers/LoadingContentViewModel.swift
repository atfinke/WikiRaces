//
//  LoadingContentViewModel.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/27/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

class LoadingContentViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var activityOpacity: Double = 1

    @Published var disclaimerButtonTitle: String = " "
    @Published var disclaimerButtonOpacity: Double = 0
}
