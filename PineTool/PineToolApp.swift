//
//  PineToolApp.swift
//  PineTool
//
//  Created by Lachlan Bell on 22/4/2023.
//  Copyright © 2023 Lachlan Bell. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

@main
struct PineToolApp: App {
    @AppStorage("keep-awake") var keepAwake = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(PinecilManager())
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = keepAwake
                }
                .onChange(of: keepAwake) {
                    UIApplication.shared.isIdleTimerDisabled = $0
                }
        }
    }
}
