// Connection.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Formbound
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

import CLibpq

public class PostgreSQLConnection: Connection {
    public enum Error: ErrorType {
        case ConnectFailed(reason: String)
        case ExecutionError(reason: String)
    }

    public enum Status {
        case Bad
        case Started
        case Made
        case AwatingResponse
        case AuthOK
        case SettingEnvironment
        case SSLStartup
        case OK
        case Unknown
        case Needed

        public init(status: ConnStatusType) {
            switch status {
            case CONNECTION_NEEDED:
                self = .Needed
                break

            case CONNECTION_OK:
                self = .OK
                break
            case CONNECTION_STARTED:
                self = .Started
                break
            case CONNECTION_MADE:
                self = .Made
                break
            case CONNECTION_AWAITING_RESPONSE:
                self = .AwatingResponse
                break
            case CONNECTION_AUTH_OK:
                self = .AuthOK
                break
            case CONNECTION_SSL_STARTUP:
                self = .SSLStartup
                break
            case CONNECTION_SETENV:
                self = .SettingEnvironment
                break
            case CONNECTION_BAD:
                self = .Bad
                break
            default:
                self = .Unknown
                break
            }
        }
    }

    public class Info: ConnectionInfo, ConnectionStringConvertible {

        public var connectionString: String {
            var userInfo = ""
            if let user = user {
                userInfo = user

                if let password = password {
                    userInfo += ":\(password)@"
                }
                else {
                  userInfo += "@"
                }
            }

            return "postgresql://\(userInfo)\(host):\(port)/\(database)"
        }

        public required convenience init(connectionString: String) {
            guard let uri = try? URI(string: connectionString) else {
                fatalError("Failed to construct URI from \(connectionString)")
            }

            guard let host = uri.host else {
                fatalError("Missing host in connection string")
            }

            guard let database = uri.path?.splitBy("/").last else {
                fatalError("Missing database in connection string")
            }

            self.init(
                host: host,
                database: database,
                port: UInt(uri.port ?? 5432),
                user: uri.userInfo?.username,
                password: uri.userInfo?.password
            )
        }

        public required convenience init(stringLiteral: String) {
            self.init(connectionString: stringLiteral)
        }

        public required convenience init(extendedGraphemeClusterLiteral value: String) {
            self.init(connectionString: value)
        }

        public required convenience init(unicodeScalarLiteral value: String) {
            self.init(connectionString: value)
        }

        public var description: String {
            return connectionString
        }

        public convenience init(host: String, database: String, user: String? = nil, password: String? = nil) {
            self.init(host: host, database: database, port: 5432, user: user, password: password)
        }
    }

    private(set) public var connectionInfo: Info

    private var connection: COpaquePointer = nil

    public var status: Status {
        return Status(status: PQstatus(self.connection))
    }

    public required init(_ connectionInfo: Info) {
        self.connectionInfo = connectionInfo
    }


    deinit {
        close()
    }

    public func open() throws {
        connection = PQconnectdb(connectionInfo.connectionString)

        if let errorMessage = String.fromCString(PQerrorMessage(connection)) where !errorMessage.isEmpty {
            throw Error.ConnectFailed(reason: errorMessage)
        }
    }

    public func close() {
        PQfinish(connection)
        connection = nil
    }

    public func createSavePointNamed(name: String) throws {
        try execute("SAVEPOINT $1", parameters: name)
    }

    public func rollbackToSavePointNamed(name: String) throws {
        try execute("ROLLBACK TO SAVEPOINT $1", parameters: name)
    }

    public func releaseSavePointNamed(name: String) throws {
        try execute("RELEASE SAVEPOINT $1", parameters: name)
    }

    public func execute(statement: String, parameters: [QueryParameterConvertible]) throws -> PostgreSQLResult {
        let values = UnsafeMutablePointer<UnsafePointer<Int8>>.alloc(parameters.count)

        defer {
            values.destroy()
            values.dealloc(parameters.count)
        }


        var temps = [Array<UInt8>]()
        for (i, value) in parameters.enumerate() {

            switch value.queryParameterValue {
            case .Binary(let binary):
                values[i] = UnsafePointer<Int8>(binary)
                break
            case .Text(let string):
                temps.append(Array<UInt8>(string.utf8) + [0])
                values[i] = UnsafePointer<Int8>(temps.last!)
                break
            }
        }

        return try PostgreSQLResult(
            PQexecParams(connection,
                statement,
                Int32(parameters.count),
                nil,
                values,
                nil,
                nil,
                0
            )
        )
    }
    
    /**
     Execute a request stored in the file. 
     Notice that it execute a non-parameterized request.
     
     - parameter path: the path to the input file.
    
     - throws: the call can throw either an error caused by the reading of the file or a PostgreSQLResult.Error.BadStatus error
    
     - returns: returns a PostgreSQLResult
     */
    public func executeFromFile(atPath path: String) throws -> PostgreSQLResult {
        
        let file = try File(path: path, mode: .Read)
        let data = try file.read()
        let statement = try String(data: data)
        
        
        return try PostgreSQLResult(
            PQexec(connection,
                statement
            )
        )
    }
}
