//
//  Unknown.swift
//  packetCapture1
//
//  Created by Darrell Root on 1/24/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation

public struct Unknown: CustomStringConvertible {
    public let data: Data
    
    public var description: String {
        return "unknown"
    }
    
    public var verboseDescription: String {
        return "unknown"
    }
    
    public static let completely = Unknown(data: Data()) // empty for error cases

    public var hexdump: String {
        return self.data.hexdump
    }

    
    init(data: Data) {
        self.data = data
    }
}
