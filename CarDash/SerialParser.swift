//
//  SerialParser.swift
//  CarDash
//
//  Created by Alexandre Blin on 14/01/2017.
//  Copyright © 2017 Alexandre Blin. All rights reserved.
//

import Foundation

protocol SerialParserDelegate: class {
    func serialParser(_ serialParser: SerialParser, didReceiveFrame frameID: UInt8, data: [UInt8])
}

/// A `SerialParser` parses raw data coming from a serial device (such as an Arduino).
/// The raw data must be in a specific format (see https://github.com/alexandreblin/arduino-peugeot-can)
class SerialParser {
    enum ControlChars {
        static let start: UInt8     = 0x12
        static let end: UInt8       = 0x13
        static let escape: UInt8    = 0x7E
        static let escapeXor: UInt8 = 0x20
    }

    weak var delegate: SerialParserDelegate?

    /// Temp buffer containing currently parsed data
    private var dataBuffer = [UInt8]()

    private var isInFrame = false
    private var shouldUnescapeNextByte = false

    init(delegate: SerialParserDelegate? = nil) {
        self.delegate = delegate
    }

    /// Parses serial data. This can be called as many times
    /// as needed, with complete or partial data. It will call
    /// the delegate's method when a frame is detected and parsed.
    ///
    /// - Parameter data: The data to parse
    func parse(serialData data: Data) {
        var iterator = data.makeIterator()
        while let byte = iterator.next() {
            if !isInFrame && byte != ControlChars.start {
                continue
            }

            if byte == ControlChars.start {
                isInFrame = true
                dataBuffer.removeAll()
            } else if byte == ControlChars.end {
                isInFrame = false

                if dataBuffer.count >= 3 {
                    delegate?.serialParser(self, didReceiveFrame: dataBuffer[1], data: Array(dataBuffer.suffix(from: 2)))
                } else {
                    print("ERROR: Frame is too short")
                }
            } else if byte == ControlChars.escape {
                // We found an escape character, unescape the next byte.
                shouldUnescapeNextByte = true
            } else {
                if shouldUnescapeNextByte {
                    shouldUnescapeNextByte = false
                    dataBuffer.append(byte ^ ControlChars.escapeXor)
                } else {
                    dataBuffer.append(byte)
                }
            }
        }
    }
}
