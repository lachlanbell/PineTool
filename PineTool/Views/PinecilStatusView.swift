//
//  PinecilStatusView.swift
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

struct PinecilStatusView: View {
    @EnvironmentObject var pinecilManager: PinecilManager

    @ViewBuilder
    var statStack: some View {
        VStack(spacing: 4) {
            PinecilStat(
                title: "Input Voltage",
                value: "\(Double(pinecilManager.bulkData?.inputVoltage ?? 0) / 10.0) V"
            )

            PinecilStat(
                title: "Handle Temperature",
                value: "\(Double(pinecilManager.bulkData?.handleTemperature ?? 0) / 10.0) ℃"
            )

            PinecilStat(
                title: "Uptime",
                value: "\(Int(Double(pinecilManager.bulkData?.uptime ?? 0) / 10.0)) sec"
            )

            PinecilStat(
                title: "Power Source",
                value: PowerSource(rawValue: pinecilManager.bulkData?.powerSource ?? .max)?.description ?? "Unknown"
            )
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
    }

    @ViewBuilder
    var disconnectButton: some View {
        Button {
            pinecilManager.disconnect()
        } label: {
            Text("\(Image(systemName: "antenna.radiowaves.left.and.right.slash")) Disconnect")
                .foregroundColor(.red)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.3))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            statStack

            Divider()

            disconnectButton
        }
        .frame(maxWidth: .infinity)
        .clipShape(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private struct PinecilStat: View {
        let title: LocalizedStringKey
        let value: String

        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundColor(.secondary)
                    .font(.caption)

                Spacer()

                Text(value)
                    .font(.caption).monospacedDigit()
            }
        }
    }
}
