//
//  GenerateSwiftUICoreImageApp.swift
//  GenerateSwiftUICoreImage
//
//  Created by Dan Wood on 6/25/24.
//

import SwiftUI

@main
struct GenerateSwiftUICoreImageApp: App {
    var body: some Scene {
        let _ = dumpFilters()
		let _ = dumpUnknownProperties()
        WindowGroup {
            ContentView()
        }
    }
}
