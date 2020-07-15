import Foundation
import NIO
import NIOHTTP1

open class IncomingMessage {

    public let header: HTTPRequestHead // <= from NIOHTTP1
    public let _channel: Channel
    public var userInfo = [String: Any]()

    init(header: HTTPRequestHead, channel: Channel) {
        self.header = header
        self._channel = channel
    }
}
