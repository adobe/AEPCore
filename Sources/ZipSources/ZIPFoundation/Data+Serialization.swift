
import Foundation

protocol DataSerializable {
    static var size: Int { get }
    init?(data: Data, additionalDataProvider: (Int) throws -> Data)
}

extension Data {
    enum DataError: Error {
        case unreadableFile
        case unwritableFile
    }

    func scanValue<T>(start: Int) -> T {
        let subdata = self.subdata(in: start..<start+MemoryLayout<T>.size)
        #if swift(>=5.0)
        return subdata.withUnsafeBytes { $0.load(as: T.self) }
        #else
        return subdata.withUnsafeBytes { $0.pointee }
        #endif
    }

    static func readStruct<T>(from file: UnsafeMutablePointer<FILE>, at offset: Int) -> T? where T: DataSerializable {
        fseek(file, offset, SEEK_SET)
        guard let data = try? self.readChunk(of: T.size, from: file) else {
            return nil
        }
        let structure = T(data: data, additionalDataProvider: { (additionalDataSize) -> Data in
            return try self.readChunk(of: additionalDataSize, from: file)
        })
        return structure
    }

    static func readChunk(of size: Int, from file: UnsafeMutablePointer<FILE>) throws -> Data {
        let alignment = MemoryLayout<UInt>.alignment
        #if swift(>=4.1)
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
        #else
        let bytes = UnsafeMutableRawPointer.allocate(bytes: size, alignedTo: alignment)
        #endif
        let bytesRead = fread(bytes, 1, size, file)
        let error = ferror(file)
        if error > 0 {
            throw DataError.unreadableFile
        }
        #if swift(>=4.1)
        return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: .custom({ buf, _ in buf.deallocate() }))
        #else
        let deallocator = Deallocator.custom({ buf, _ in buf.deallocate(bytes: size, alignedTo: 1) })
        return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: deallocator)
        #endif
    }

    static func write(chunk: Data, to file: UnsafeMutablePointer<FILE>) throws -> Int {
        var sizeWritten = 0
        chunk.withUnsafeBytes { (rawBufferPointer) in
            if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
                let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                sizeWritten = fwrite(pointer, 1, chunk.count, file)
            }
        }
        let error = ferror(file)
        if error > 0 {
            throw DataError.unwritableFile
        }
        return sizeWritten
    }
}
