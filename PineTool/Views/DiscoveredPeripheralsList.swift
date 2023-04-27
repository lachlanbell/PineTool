//
//  DiscoveredPeripheralsList.swift
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
import CoreBluetooth

struct DiscoveredPeripheralsList: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var pinecilManager: PinecilManager

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    if !pinecilManager.discoveredPeripherals.isEmpty {
                        Section("Discovered Devices") {
                            ForEach(pinecilManager.discoveredPeripherals) { peripheral in
                                Button {
                                    pinecilManager.connect(to: peripheral)
                                } label: {
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading) {
                                            Text(pinecilManager.peripheralNames[peripheral] ?? "Unknown")
                                                .foregroundColor(.primary)
                                        }

                                        Spacer()

                                        if case let .connecting(connectingPeripheral) = pinecilManager.state,
                                           connectingPeripheral == peripheral {
                                            ProgressView()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if pinecilManager.discoveredPeripherals.isEmpty {
                    VStack(alignment: .center) {
                        Spacer()

                        VStack(alignment: .center, spacing: 16) {
                            ProgressView()
                            Text("Scanning for devices…")
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Link(
                            "\(Image(systemName: "questionmark.circle.fill")) Can’t find your device?",
                            destination: URL(string: "https://lachy.io/pinetool/help")!
                        )
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Connect")
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .bold()
                    }

                }
            }
        }
        .onDisappear {
            pinecilManager.stopScan()
        }
        .onReceive(pinecilManager.$state) { state in
            if case .connected = state {
                dismiss()
            }
        }
    }
}

extension CBPeripheral: Identifiable {
    public var id: UUID { self.identifier }
}
