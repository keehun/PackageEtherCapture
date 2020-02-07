//
//  IPv6.swift
//  packetCapture1
//
//  Created by Darrell Root on 1/24/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation
import Network
import Logging

public struct IPv6: EtherDisplay, Codable {
    public let data: Data
    public let version: UInt8
    public let trafficClass: UInt8
    public let flowLabel: UInt
    public let payloadLength: UInt
    public let nextHeader: UInt8
    public let hopLimit: UInt8
    public let sourceIP: IPv6Address
    public let destinationIP: IPv6Address
    public let layer4: Layer4

    public var description: String {
        return "IPv\(version) \(sourceIP.debugDescription) > \(destinationIP.debugDescription) payload \(payloadLength) nextHeader \(nextHeader) hopLimit \(hopLimit)"
    }
    
    public var verboseDescription: String {
        return "IPv\(version) \(sourceIP.debugDescription) > \(destinationIP.debugDescription) payload \(payloadLength) nextHeader \(nextHeader) trafficClass \(trafficClass) flowLabel \(flowLabel) hopLimit \(hopLimit)"
    }

    public var hexdump: String {
        return self.data.hexdump
    }
    
    init?(data: Data) {
        guard data.count >= 40 else {
            EtherCapture.logger.error("IPv6: error short packet header size \(data.count)")
            return nil
        }
        self.data = data

        self.version = (data[data.startIndex] & 0b11110000) >> 4
        self.trafficClass = (data[data.startIndex] & 0b00001111) << 4 + (data[data.startIndex + 1] & 0b11110000) >> 4
        
        self.flowLabel = UInt(data[data.startIndex + 1] & 0b00001111) * 256 * 256 + UInt(data[data.startIndex + 2]) * 256 + UInt(data[data.startIndex + 3])
        
        self.payloadLength = UInt(data[data.startIndex + 4]) * 256 + UInt(data[data.startIndex + 5])
        
        self.nextHeader = data[data.startIndex + 6]
        self.hopLimit = data[data.startIndex + 7]

        if let sourceIP = IPv6Address(data[data.startIndex + 8 ..< data.startIndex + 24]) {
            self.sourceIP = sourceIP
        } else {
            return nil
        }
        if let destinationIP = IPv6Address(data[data.startIndex + 24 ..< data.startIndex + 40]) {
            self.destinationIP = destinationIP
        } else {
            return nil
        }
        
        let finalHeaderIndex = data.startIndex + 20 //TODO deal with extension headers
        if finalHeaderIndex >= data.endIndex {  // invalid case
            self.layer4 = .unknown(Unknown.completely)
        } else {
            switch nextHeader {
            case 6:
                if let tcp = Tcp(data: data[data.startIndex + 20 ..< data.endIndex]) {
                    self.layer4 = .tcp(tcp)
                } else {
                    self.layer4 = .unknown(Unknown(data: data[data.startIndex + 20 ..< data.endIndex]))
                }
            case 17:
                if let udp = Udp(data: data[finalHeaderIndex ..< data.endIndex]) {
                    self.layer4 = .udp(udp)
                } else {
                    self.layer4 = .unknown(Unknown(data: data[finalHeaderIndex ..< data.endIndex]))
                }
            default:
                self.layer4 = .unknown(Unknown(data: data[finalHeaderIndex ..< data.endIndex]))
            }
            
        }// if finalHeaderIndex >= data.endIndex else

    }
}
