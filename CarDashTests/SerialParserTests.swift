//
//  SerialParserTests.swift
//  CarDash
//
//  Created by Alexandre Blin on 14/01/2017.
//  Copyright © 2017 Alexandre Blin. All rights reserved.
//

import XCTest
@testable import CarDash

class SerialParserTests: XCTestCase, SerialParserDelegate {
    private let parser = SerialParser()

    private struct Frame {
        let id: UInt8
        let data: [UInt8]
    }

    private var receivedFrames = [Frame]()

    func serialParser(_ serialParser: SerialParser, didReceiveFrame frameID: UInt8, data: [UInt8]) {
        let frame = Frame(id: frameID, data: data)

        receivedFrames.append(frame)
    }

    override func setUp() {
        super.setUp()

        parser.delegate = self
        receivedFrames.removeAll()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSimpleFrame() {
        let data = Data(bytes: [0x12, 0x02, 0x01, 0x42, 0x13])

        parser.parse(serialData: data)

        if receivedFrames.count != 1 {
            XCTFail("Incorrect received frames count")
            return
        }

        let frame = receivedFrames[0]

        XCTAssertEqual(frame.id, 0x01)
        XCTAssertEqual(frame.data, [0x42])
    }

    func testEscapedFrame() {
        let data = Data(bytes: [0x12, 0x03, 0x02, 0x7E, 0x33, 0x42, 0x13])

        parser.parse(serialData: data)

        if receivedFrames.count != 1 {
            XCTFail("Incorrect received frames count")
            return
        }

        let frame = receivedFrames[0]

        XCTAssertEqual(frame.id, 0x02)
        XCTAssertEqual(frame.data, [0x13, 0x42])
    }

    func testComplexEscapedFrame() {
        let data = Data(bytes: [0x12, 0x7E, 0x33, 0x7E, 0x20, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x7E, 0x32, 0x13])

        parser.parse(serialData: data)

        if receivedFrames.count != 1 {
            XCTFail("Incorrect received frames count")
            return
        }

        let frame = receivedFrames[0]

        XCTAssertEqual(frame.id, 0x00)
        XCTAssertEqual(frame.data, [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12])
    }

    func testComplexEscapedFrameChunked() {
        let dataChunk1 = Data(bytes: [0x12, 0x7E, 0x33, 0x7E])
        let dataChunk2 = Data(bytes: [0x20, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])
        let dataChunk3 = Data(bytes: [0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x7E, 0x32, 0x13])

        parser.parse(serialData: dataChunk1)
        parser.parse(serialData: dataChunk2)
        parser.parse(serialData: dataChunk3)

        if receivedFrames.count != 1 {
            XCTFail("Incorrect received frames count")
            return
        }

        let frame = receivedFrames[0]

        XCTAssertEqual(frame.id, 0x00)
        XCTAssertEqual(frame.data, [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12])
    }

    func testParsingPerformance() {
        guard let url = Bundle(for: type(of: self)).url(forResource: "cansample", withExtension: "hex"),
            let data = try? Data(contentsOf: url) else {
                XCTFail("Could not load sample hex file")
                return
        }

        measure {
            self.receivedFrames.removeAll()
            self.parser.parse(serialData: data)
            XCTAssertEqual(self.receivedFrames.count, 10000)
        }
    }

    func testFrameAfterMalformedData() {
        let data = Data(bytes: [0x12, 0x13, 0x20, 0x12, 0x7E, 0x12, 0x12, 0x03, 0x01, 0x02, 0x03, 0x13])

        parser.parse(serialData: data)

        if receivedFrames.count != 1 {
            XCTFail("Incorrect received frames count")
            return
        }

        let frame = receivedFrames[0]

        XCTAssertEqual(frame.id, 0x01)
        XCTAssertEqual(frame.data, [0x02, 0x03])
    }

}
