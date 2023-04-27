//
//  ContentView.swift
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
import Introspect

struct ContentView: View {

    @EnvironmentObject private var pinecilManager: PinecilManager

    @State private var presentingPeripheralList = false
    @State private var presentingSettings = false
    @State private var viewController: UIViewController?

    @ViewBuilder
    var connectButton: some View {
        Button {
            pinecilManager.scan()
            presentingPeripheralList = true
        } label: {
            Text("\(Image(systemName: "antenna.radiowaves.left.and.right")) Connect")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor.opacity(0.3))
                .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
    }

    @ViewBuilder
    var largeStats: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center) {
                Text("\(pinecilManager.bulkData?.tipTemperature ?? 0) ℃")
                    .font(.title2).monospacedDigit()
                    .bold()

                Text("Temperature")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(alignment: .center) {
                Text("\(Double(pinecilManager.bulkData?.estimatedWattage ?? 0) / 10.0, specifier: "%.1f") W")
                    .font(.title2).monospacedDigit()
                    .bold()

                Text("Power")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    @ViewBuilder
    var setPoint: some View {
        HStack(alignment: .center) {
            Text("Setpoint")
                .foregroundColor(.secondary)

            Spacer()

            Button {
                viewController?.present(
                    TemperatureSetViewController(
                        temperature: pinecilManager.bulkData?.setpoint,
                        setCallback: {
                            pinecilManager.writeSetpoint($0)
                        },
                        validateCallback: { value in
                            guard let maxTemp = pinecilManager.bulkData?.maxTemperature else {
                                return false
                            }
                            guard value >= 50 else { return false }
                            return value <= maxTemp
                        }
                    ),
                    animated: true
                )
            } label: {
                Text("\(pinecilManager.bulkData?.setpoint ?? 0) ℃")
                    .font(Font.system(size: 18, weight: .medium, design: .default).monospacedDigit())
                    .frame(width: 80, height: 36, alignment: .center)
                    .foregroundColor(Color(UIColor.label.withAlphaComponent(0.6)))
                    .background(
                        Color(
                            UIColor
                                .tertiarySystemFill
                                .multiplyAlpha(by: pinecilManager.bulkData?.setpoint == nil ? 0.6 : 1)
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .padding(-8)
            .disabled(pinecilManager.bulkData?.setpoint == nil)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if pinecilManager.state == .disconnected || pinecilManager.state == .scanning {
                        connectButton
                    } else {
                        PinecilStatusView()
                    }

                    largeStats
                        .fixedSize(horizontal: false, vertical: true)

                    TemperaturePowerChart()

                    setPoint
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("PineTool")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $presentingPeripheralList) {
                DiscoveredPeripheralsList()
            }
            .sheet(isPresented: $presentingSettings) {
                SettingsView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .introspectViewController { viewController in
                // Introspecting and storing the host view controller like this
                // is hacky, but unfortunately SwiftUI doesn't have the
                // capability to present a `UIViewControllerRepresentable` with
                // a custom transition.
                self.viewController = viewController
            }
        }
    }
}

private extension UIColor {
    /// Multiply the alpha component of an already-translucent colour
    func multiplyAlpha(by alpha: CGFloat) -> UIColor {
        var (red, green, blue, oldAlpha) = (CGFloat.zero, CGFloat.zero, CGFloat.zero, CGFloat.zero)
        self.getRed(&red, green: &green, blue: &blue, alpha: &oldAlpha)

        return UIColor(red: red, green: green, blue: blue, alpha: alpha * oldAlpha)
    }
}
