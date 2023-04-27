//
//  PowerSource.swift
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

enum PowerSource: UInt32, CustomStringConvertible {
    case dc = 0
    case usb = 1
    case pdVBUS = 2
    case pd = 3

    var description: String {
        switch self {
        case .dc: return "DC"
        case .usb: return "USB"
        case .pdVBUS: return "USB-PD (VBUS)"
        case .pd: return "USB-PD"
        }
    }
}
