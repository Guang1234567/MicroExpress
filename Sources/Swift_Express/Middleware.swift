import Foundation

public typealias Next = (Any...) -> Void

public typealias Middleware =
        (IncomingMessage,
         ServerResponse,
         @escaping Next) -> Void
