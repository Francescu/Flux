// File.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CLibvenice

public var standardInputStream = try! File(fileDescriptor: dup(STDIN_FILENO))
public var standardOutputStream = try! File(fileDescriptor: dup(STDOUT_FILENO))
public var standardErrorStream = try! File(fileDescriptor: dup(STDERR_FILENO))

public final class File {
	public enum Mode {
		case Read
        case CreateWrite
		case TruncateWrite
		case AppendWrite
		case ReadWrite
        case CreateReadWrite
		case TruncateReadWrite
		case AppendReadWrite

        var value: Int32 {
            switch self {
            case .Read: return O_RDONLY
            case .CreateWrite: return (O_WRONLY | O_CREAT | O_EXCL)
            case .TruncateWrite: return (O_WRONLY | O_CREAT | O_TRUNC)
            case .AppendWrite: return (O_WRONLY | O_CREAT | O_APPEND)
            case .ReadWrite: return (O_RDWR)
            case .CreateReadWrite: return (O_RDWR | O_CREAT | O_EXCL)
            case .TruncateReadWrite: return (O_RDWR | O_CREAT | O_TRUNC)
            case .AppendReadWrite: return (O_RDWR | O_CREAT | O_APPEND)
            }
        }
	}
	
    private var file: mfile
    public private(set) var closed = false

    public func tell() throws -> Int {
        let position = Int(filetell(file))
        try FileError.assertNoError()
        return position
    }

    public func seek(position: Int) throws -> Int {
        let position = Int(fileseek(file, Int64(position)))
        try FileError.assertNoError()
        return position
    }

    public func eof() throws -> Bool {
        let isEof = fileeof(file)
        try FileError.assertNoError()
        return isEof != 0
    }

    public init(file: mfile) throws {
        self.file = file
        try FileError.assertNoError()
    }
	
	public convenience init(path: String, mode: Mode = .Read) throws {
        try self.init(file:  fileopen(path, mode.value, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH))
	}

    public convenience init(fileDescriptor: FileDescriptor) throws {
        try self.init(file: fileattach(fileDescriptor))
    }
	
	deinit {
        if !closed && file != nil {
            fileclose(file)
        }
	}
	
    public func write(data: Data, flush shouldFlush: Bool = true, deadline: Deadline = noDeadline) throws {
        try assertNotClosed()

        data.withUnsafeBufferPointer {
            filewrite(file, $0.baseAddress, $0.count, deadline)
        }

        try FileError.assertNoError()
        
        if shouldFlush {
            try flush(deadline)
        }

        try FileError.assertNoError()
	}

    public func read(length length: Int, deadline: Deadline = noDeadline) throws -> Data {
        try assertNotClosed()

        var data = Data.bufferWithSize(length)

        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            fileread(file, $0.baseAddress, $0.count, deadline)
        }

        try FileError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return processedDataFromSource(data, bytesProcessed: bytesProcessed)
    }

    public func read(deadline: Deadline = noDeadline) throws -> Data {
        try seek(0)
        var data = Data()

        while true {
            data += try read(length: 256)

            if try eof() {
                break
            }
        }

        return data
    }

    public func flush(deadline: Deadline = noDeadline) throws {
        try assertNotClosed()

        fileflush(file, deadline)

        try FileError.assertNoError()
    }

    public func attach(fileDescriptor: FileDescriptor) throws {
        if !closed {
            try close()
        }

        file = fileattach(fileDescriptor)
        try FileError.assertNoError()
        closed = false
    }

    public func detach() throws -> FileDescriptor {
        try assertNotClosed()
        closed = true
        return filedetach(file)
    }

    public func close() throws {
        try assertNotClosed()
        closed = true
        fileclose(file)
    }

    func assertNotClosed() throws {
        if closed {
            throw FileError.closedFileError
        }
    }
}

extension File {
    public func write(convertible: DataConvertible, flush: Bool = true, deadline: Deadline = noDeadline) throws {
        try write(convertible.data, flush: flush, deadline: deadline)
    }
}

extension File {
    
    public class func contentsOfDirectoryAtPath(path: String) throws -> [String] {
        var contents: [String] = []
        
        let dir = opendir(path)
        
        if dir == nil {
            throw FileError.Unknown(description: "Could not open directory at \(path)")
        }
        
        defer {
            closedir(dir)
        }
        
        let excludeNames = [".", ".."]
        
        var entry: UnsafeMutablePointer<dirent> = readdir(dir)
        
        while entry != nil {
            if let entryName = withUnsafePointer(&entry.memory.d_name, { (ptr) -> String? in
                let int8Ptr = unsafeBitCast(ptr, UnsafePointer<Int8>.self)
                return String.fromCString(int8Ptr)
            }) {
                
                // TODO: `entryName` should be limited in length to `entry.memory.d_namlen`.
                if !excludeNames.contains(entryName) {
                    contents.append(entryName)
                }
            }
            
            entry = readdir(dir)
        }
        
        return contents
    }
    
    public class func fileExistsAtPath(path: String, inout isDirectory: Bool) -> Bool {
        var s = stat()
        if lstat(path, &s) >= 0 {
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if stat(path, &s) >= 0 {
                    isDirectory = (s.st_mode & S_IFMT) == S_IFDIR
                } else {
                    return false
                }
            } else {
                isDirectory = (s.st_mode & S_IFMT) == S_IFDIR
            }
            
            // don't chase the link for this magic case -- we might be /Net/foo
            // which is a symlink to /private/Net/foo which is not yet mounted...
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if (s.st_mode & S_ISVTX) == S_ISVTX {
                    return true
                }
                // chase the link; too bad if it is a slink to /Net/foo
                stat(path, &s) >= 0
            }
        } else {
            return false
        }
        return true
    }
	
}
