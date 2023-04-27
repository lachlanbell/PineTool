//
//  TemperaturePowerChart.swift
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
import Charts

struct TemperaturePowerChart: View {
    @EnvironmentObject var pinecilManager: PinecilManager

    private let maxSamples = 60

    private struct DataPoint {
        let index: Int
        let power: Double
        let temperature: Double
    }

    private var data: [DataPoint] {
        let powerData = Array(pinecilManager.powerSamples.suffix(maxSamples))
        let temperatureData = Array(pinecilManager.temperatureSamples.suffix(maxSamples))

        let sampleCount = min(powerData.count, temperatureData.count)

        return Array(0..<sampleCount).map { index in
            return DataPoint(
                index: index,
                power: powerData[index],
                temperature: temperatureData[index]
            )
        }
    }

    var body: some View {
        Chart {
            ForEach(data, id: \.index) { dataPoint in
                LineMark(
                    x: .value("", dataPoint.index),
                    y: .value("Temperature", dataPoint.temperature / 450.0)
                )
                .foregroundStyle(by: .value("Value", "Temperature"))

                LineMark(
                    x: .value("", dataPoint.index),
                    y: .value("Power", dataPoint.power / 90.0)
                )
                .foregroundStyle(by: .value("Value", "Power"))
            }
            .interpolationMethod(.catmullRom)
        }
        .chartForegroundStyleScale([
           "Temperature": .red,
           "Power": .blue
        ])
        .chartYScale(domain: 0...1)
        .chartXAxis(.hidden)
        .chartYAxis {
            let defaultStride = Array(stride(from: 0, to: 1, by: 1.0/9.0))

            let powerStride = Array(stride(from: 0, to: 90, by: 10))
            AxisMarks(position: .trailing, values: defaultStride) { axis in
                AxisGridLine()
                let value = powerStride[axis.index]
                AxisValueLabel("\(value) W", centered: false)
            }

            let temperatureStride = Array(stride(from: 0, to: 450, by: 50))
            AxisMarks(position: .leading, values: defaultStride) { axis in
                AxisGridLine()
                let value = temperatureStride[axis.index]
                AxisValueLabel("\(value) ℃", centered: false)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, idealHeight: 300)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}
