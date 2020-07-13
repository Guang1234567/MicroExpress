import Foundation
import NIO
import NIOHTTP1

public class ServerResponse {

    public var _status = HTTPResponseStatus.ok
    public var _headers = HTTPHeaders()
    public let _channel: Channel
    private var _didWriteHeader = false
    private var _didEnd = false

    public init(channel: Channel) {
        self._channel = channel
    }

    /// Check whether we already wrote the response header.
    /// If not, do so.
    func flushHeader() {
        guard !_didWriteHeader else {
            return
        } // done already
        _didWriteHeader = true

        let head = HTTPResponseHead(version: .init(major: 1, minor: 1),
                                    status: _status, headers: _headers)
        let part = HTTPServerResponsePart.head(head)
        _ = _channel.writeAndFlush(part).recover(handleError)
    }

    func handleError(_ error: Error) {
        print("ERROR:", error)
        end()
    }

    func end() {
        guard !_didEnd else {
            return
        }
        _didEnd = true
        _ = _channel.writeAndFlush(HTTPServerResponsePart.end(nil))
                    .map {
                        self._channel.close()
                    }
    }
}

public extension ServerResponse {

    /// A more convenient header accessor. Not correct for
    /// any header.
    subscript(name: String) -> String? {
        set {
            assert(!_didWriteHeader, "header is out!")
            if let v = newValue {
                _headers.replaceOrAdd(name: name, value: v)
            } else {
                _headers.remove(name: name)
            }
        }
        get {
            return _headers[name].joined(separator: ", ")
        }
    }
}

public extension ServerResponse {

    /// An Express like `send()` function.
    public func send(_ s: String) {
        flushHeader()

        var buffer = _channel.allocator.buffer(capacity: s.count)
        buffer.writeString(s)

        let part = HTTPServerResponsePart.body(.byteBuffer(buffer))

        _ = _channel.writeAndFlush(part)
                    .recover(handleError)
                    .map(end)
    }

    /// An Express like `send()` function which arbitrary "Data" objects
    /// (i.e. collections of type UInt8)
    func send<S: Collection>(bytes: S) where S.Element == UInt8 {
        flushHeader()
        guard !_didEnd else {
            return
        }

        var buffer = _channel.allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)

        let part = HTTPServerResponsePart.body(.byteBuffer(buffer))
        _ = _channel.writeAndFlush(part)
                    .recover(handleError)
                    .map {
                        self.end()
                    }
    }

    /// Send a Codable object as JSON to the client.
    func json<T: Encodable>(_ model: T) {
        // create a Data struct from the Codable object
        let data: Data
        do {
            data = try JSONEncoder().encode(model)
        } catch {
            return handleError(error)
        }

        // setup JSON headers
        self["Content-Type"] = "application/json"
        self["Content-Length"] = "\(data.count)"

        // send the headers and the data
        flushHeader()

        var buffer = _channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        let part = HTTPServerResponsePart.body(.byteBuffer(buffer))

        _ = _channel.writeAndFlush(part)
                    .recover(handleError)
                    .map(end)
    }
}