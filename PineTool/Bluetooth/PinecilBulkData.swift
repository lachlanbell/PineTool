//
//  PinecilBulkData.swift
//  PineTool
//
//  Created by Lachlan Bell on 22/4/2023.
//  Copyright © 2023 Lachlan Bell. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// See https://github.com/Ralim/IronOS/blob/5a36b0479cef995ecfb1e75638579d11cb891feb/source/Core/BSP/Pinecilv2/ble_handlers.cpp#L151-L166
struct PinecilBulkData {
    /// Current temp
    let tipTemperature: UInt32
    /// Setpoint
    let setpoint: UInt32
    /// Input voltage
    let inputVoltage: UInt32
    /// Handle X10 Temp in C
    let handleTemperature: UInt32
    /// Power as PWM level
    let powerPWM: UInt32
    /// Power src
    let powerSource: UInt32
    /// Tip resistance
    let tipResistance: UInt32
    /// Uptime in deciseconds
    let uptime: UInt32
    /// Last movement time (deciseconds)
    let lastMovementTime: UInt32
    /// Max temp
    let maxTemperature: UInt32
    /// Raw tip in μV
    let rawTipMicrovolts: UInt32
    /// Hall sensor
    let hallSensor: UInt32
    /// Operating mode
    let operatingMode: UInt32
    /// Estimated wattage × 10
    let estimatedWattage: UInt32

    init?(data: Data) {
        guard data.count >= 56 else {
            assertionFailure()
            return nil
        }

        tipTemperature      = data.readUInt32(0)
        setpoint            = data.readUInt32(1)
        inputVoltage        = data.readUInt32(2)
        handleTemperature   = data.readUInt32(3)
        powerPWM            = data.readUInt32(4)
        powerSource         = data.readUInt32(5)
        tipResistance       = data.readUInt32(6)
        uptime              = data.readUInt32(7)
        lastMovementTime    = data.readUInt32(8)
        maxTemperature      = data.readUInt32(9)
        rawTipMicrovolts    = data.readUInt32(10)
        hallSensor          = data.readUInt32(11)
        operatingMode       = data.readUInt32(12)
        estimatedWattage    = data.readUInt32(13)
    }
}

private extension Data {
    func readUInt32(_ index: Int) -> UInt32 {
        let dataSlice = self[(index * 4)..<((index + 1) * 4)]

        return UInt32(littleEndian: dataSlice.withUnsafeBytes({
            $0.load(as: UInt32.self)
        }))
    }
}
