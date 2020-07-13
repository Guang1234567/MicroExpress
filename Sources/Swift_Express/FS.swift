import NIO

public enum fs {

    static let threadPool: NIOThreadPool = {
        let tp = NIOThreadPool(numberOfThreads: System.coreCount)
        tp.start()
        return tp
    }()

    static let fileIO = NonBlockingFileIO(threadPool: threadPool)

    public static
    func readFile(eventLoop: EventLoop,
                  path: String,
                  maxSize: Int = 1024 * 1024,
                  _ cb: @escaping (Error?, ByteBuffer?) -> ()) {

        func emit(error: Error? = nil, result: ByteBuffer? = nil) {
            if eventLoop.inEventLoop {
                cb(error, result)
            } else {
                eventLoop.execute {
                    cb(error, result)
                }
            }
        }

        threadPool.submit {
            assert($0 == .active, "unexpected cancellation")

            let fh: NIO.NIOFileHandle
            do { // Blocking:
                fh = try NIO.NIOFileHandle(path: path)
            } catch {
                return emit(error: error)
            }


            fileIO.read(fileHandle: fh,
                        byteCount: maxSize,
                        allocator: ByteBufferAllocator(),
                        eventLoop: eventLoop)
                  .map {
                      try? fh.close(); emit(result: $0)
                  }
                  .whenFailure {
                      try? fh.close(); emit(error: $0)
                  }
        }
    }
}
