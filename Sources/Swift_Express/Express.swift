import Foundation
import NIO
import NIOHTTP1

public class Express: Router {

    let _loopGroup: MultiThreadedEventLoopGroup

    deinit {
        do {
            try _loopGroup.syncShutdownGracefully()
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
        }
    }

    override
    public init() {
        _loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }

    public func listen(_ port: Int) {
        let reuseAddrOpt = ChannelOptions.socket(
                SOL_SOCKET,
                SO_REUSEADDR
        )
        let bootstrap = ServerBootstrap(group: _loopGroup)
                .serverChannelOption(ChannelOptions.backlog, value: 256)
                .serverChannelOption(reuseAddrOpt, value: 1)
                .childChannelInitializer { channel in
                    channel.pipeline.configureHTTPServerPipeline().flatMap {
                        channel.pipeline.addHandler(MyHttpHandler(router: self))
                    }
                }
                .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
                .childChannelOption(reuseAddrOpt, value: 1)
                .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        do {
            let serverChannel = try bootstrap.bind(host: "localhost", port: port).wait()
            print("Server running on:", serverChannel.localAddress!)
            try serverChannel.closeFuture.wait() // runs forever
        } catch {
            fatalError("failed to start server: \(error)")
        }
    }
}

final class MyHttpHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart

    let router: Router

    init(router: Router) {
        self.router = router
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)

        switch reqPart {
            case .head(let header):
                let request = IncomingMessage(header: header, channel: context.channel)
                let response = ServerResponse(channel: context.channel)

                // trigger Router
                router.handle(request: request, response: response) {
                    (items: Any...) in
                    // the final handler
                    response._status = .notFound // 404 error
                    response.send("No middleware handled the request!")
                }

                // ignore incoming content to keep it micro :-)
            case .body, .end: break
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("ERROR : \(error.localizedDescription)")
        context.close(promise: nil)
    }
}


