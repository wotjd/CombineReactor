import Foundation
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    public func `catch`<P>(_ handler: @escaping (Failure) -> P) -> AnyPublisher<P, Never> where Output == P {
        `catch` { error in
            Just(handler(error))
        }
        .eraseToAnyPublisher()
    }

    public func sink(receiveError: @escaping ((Failure) -> Void), receiveValue: @escaping ((Output) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { (completion) in
            guard case .failure(let error) = completion else {
                return
            }

            receiveError(error)

        }, receiveValue: { output in
            receiveValue(output)
        })
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Failure == Never {
    public func send(to subject: PassthroughSubject<Output, Never>) -> AnyCancellable {
        sink { (value) in
            subject.send(value)
        }
    }
}

#if canImport(Binder)
import Binder

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Failure == Error {
    public func bind(to target: Binder<Output>) -> AnyCancellable {
        sink(receiveError: { error in
            #if DEBUG
            fatalError(error.localizedDescription)
            #else
            Swift.print(error.localizedDescription)
            #endif

        }, receiveValue: { value in
            target.on(value)
        })
    }
}
#endif
