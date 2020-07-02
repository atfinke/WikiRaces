//
//  ContentView.swift
//  WKRRaceLiveViewer
//
//  Created by Andrew Finke on 7/2/20.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var model = Model(raceCode: "buzzard")

    var body: some View {
        VStack {
            Text("\(model.host ?? "")").padding()
            Text("\(model.state?.rawValue.description ?? "-")").padding()
            Text("\(model.resultsInfo?._playersForLiveViewer.map({ $0.raceHistory?.entries.last?.page.title }).description ?? "-")").padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
