//
//  GzipArchive.swift
//  SWCompression
//
//  Created by Timofey Solomko on 29.10.16.
//  Copyright © 2016 Timofey Solomko. All rights reserved.
//

import Foundation

/**
 Error happened during unarchiving gzip archive.
 It may indicate that either the data is damaged or it might not be gzip archive at all.

 - `WrongMagic`: first two bytes of archive were not 31 and 139.
 - `WrongCompressionMethod`: compression method was other than 8 which is the only supported one.
 - `NonZeroReservedFlags`: reserved flags bits were not equal to 0, which is bad.
 */
public enum GzipError: Error {
    /// First two bytes of archive were not 31 and 139.
    case WrongMagic
    /// Compression method was other than 8 which is the only supported one.
    case WrongCompressionMethod
    /// Reserved flags bits were not equal to 0, which is bad.
    case NonZeroReservedFlags
}

/// A class with unarchive function for gzip archives.
public class GzipArchive: Archive {

    struct Flags {
        static let ftext: UInt8 = 0x01
        static let fhcrc: UInt8 = 0x02
        static let fextra: UInt8 = 0x04
        static let fname: UInt8 = 0x08
        static let fcomment: UInt8 = 0x10
    }

    struct ServiceInfo {
        let magic: [UInt8]
        let method: UInt8
        let flags: UInt8
        let mtime: UInt64
        let extraFlags: UInt8
        let osType: UInt8
        // Starting point of compressed data. Depends on presence of optional fields.
        var startPoint: Int
        // Optional fields
        var fileName: String
        var comment: String
        var crc: UInt16
    }

    static func serviceInfo(archiveData data: Data) throws -> ServiceInfo {
        // First two bytes should be correct 'magic' bytes
        let magic = data.bytes(from: 0..<2)
        guard magic == [31, 139] else { throw GzipError.WrongMagic }

        // Third byte is a method of compression. Only type 8 (DEFLATE) compression is supported
        let method = data[2]
        guard method == 8 else { throw GzipError.WrongCompressionMethod }

        // Next bytes present some service information
        var serviceInfo = ServiceInfo(magic: magic,
                                      method: method,
                                      flags: data[3],
                                      mtime: Data(data[4...7]).to(type: UInt64.self),
                                      extraFlags: data[8],
                                      osType: data[9],
                                      startPoint: 10,
                                      fileName: "", comment: "", crc: 0)

        guard (serviceInfo.flags & 0x20 == 0) &&
            (serviceInfo.flags & 0x40 == 0) &&
            (serviceInfo.flags & 0x80 == 0) else { throw GzipError.NonZeroReservedFlags }

        // Some archives may contain extra fields
        if serviceInfo.flags & Flags.fextra != 0 {
            let xlen = Data(data[serviceInfo.startPoint...serviceInfo.startPoint + 1]).to(type: UInt16.self).toInt()
            serviceInfo.startPoint += 2 + xlen
            // TODO: Add extra fields' processing
        }

        // Some archives may contain source file name (this part ends with zero byte)
        if serviceInfo.flags & Flags.fname != 0 {
            let fnameStart = serviceInfo.startPoint
            while true {
                let byte = data[serviceInfo.startPoint]
                serviceInfo.startPoint += 1
                guard byte != 0 else { break }
            }
            serviceInfo.fileName = String(data: Data(data[fnameStart..<serviceInfo.startPoint - 1]),
                                          encoding: .utf8) ?? ""
        }

        // Some archives may contain comment (this part also ends with zero)
        if serviceInfo.flags & Flags.fcomment != 0 {
            let fcommentStart = serviceInfo.startPoint
            while true {
                let byte = data[serviceInfo.startPoint]
                serviceInfo.startPoint += 1
                guard byte != 0 else { break }
            }
            serviceInfo.comment = String(data: Data(data[fcommentStart..<serviceInfo.startPoint - 1]),
                                         encoding: .utf8) ?? ""
        }

        // Some archives may contain 2-bytes checksum
        if serviceInfo.flags & Flags.fhcrc != 0 {
            serviceInfo.crc = Data(data[serviceInfo.startPoint...serviceInfo.startPoint + 1]).to(type: UInt16.self)
            serviceInfo.startPoint += 2
        }

        return serviceInfo
    }

    /**
     Unarchives gzip archive stored in `archiveData`.

     If data passed is not actually a gzip archive, `GzipError` will be thrown.

     If data inside the archive is not actually compressed with DEFLATE algorithm, `DeflateError` will be thrown.

     - Note: This function is specification compliant.

     - Parameter archiveData: Data compressed with gzip.

     - Throws: `DeflateError` or `GzipError` depending on the type of inconsistency in data.
     It may indicate that either the data is damaged or it might not be compressed with gzip or DEFLATE at all.

     - Returns: Unarchived data.
     */
    public static func unarchive(archiveData data: Data) throws -> Data {
        let info = try serviceInfo(archiveData: data)
        return try Deflate.decompress(compressedData: Data(data[info.startPoint..<data.count]))
        // TODO: Add crc check
    }

}
