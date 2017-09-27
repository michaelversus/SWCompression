// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import XCTest
import SWCompression

class BZip2CompressTests: XCTestCase {

    static let testType: String = "bz2"

    func answerTest(_ answerName: String) throws {
        guard let answerURL = Constants.url(forAnswer: answerName) else {
            XCTFail("Unable to get asnwer's URL.")
            return
        }

        let answerData = try Data(contentsOf: answerURL, options: .mappedIfSafe)

        let compressedData = BZip2.compress(data: answerData)
        let redecompressedData = try BZip2.decompress(data: compressedData)

        XCTAssertEqual(redecompressedData, answerData)
    }

    func stringTest(_ string: String) throws {
        guard let stringData = string.data(using: .utf8) else {
            XCTFail("Unable to convert String to Data.")
            return
        }

        let compressedData = BZip2.compress(data: stringData)
        let redecompressedData = try BZip2.decompress(data: compressedData)

        XCTAssertEqual(redecompressedData, stringData)
    }

    func testBZip2CompressStrings() throws {
        try stringTest("abaaba")
        try stringTest("abracadabra")
        try stringTest("cabbage")
        try stringTest("baabaabac")
        try stringTest("AAAAAAABBBBCCCD")
        try stringTest("AAAAAAA")
        try stringTest("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890")
    }

    func testBZip2CompressBytes() throws {
        var bytes = [UInt8]()
        for i: UInt8 in 0...255 {
            bytes.append(i)
        }
        try stringTest(String(data: Data(bytes: bytes), encoding: .ascii)!)
    }

    func testWithAnswer1BZip2Compress() throws {
        try answerTest("test1")
    }

    func testWithAnswer2BZip2Compress() throws {
        try answerTest("test2")
    }

    func testWithAnswer3BZip2Compress() throws {
        try answerTest("test3")
    }

    func testWithAnswer4BZip2Compress() throws {
        try answerTest("test4")
    }

    func testWithAnswer5BZip2Compress() throws {
        try answerTest("test5")
    }

//    func testWithAnswer6BZip2Compress() throws {
//        try answerTest("test6")
//    }
//
//    func testWithAnswer7BZip2Compress() throws {
//        try answerTest("test7")
//    }

    func testWithAnswer8BZip2Compress() throws {
        try answerTest("test8")
    }

    func testWithAnswer9BZip2Compress() throws {
        try answerTest("test9")
    }

}
