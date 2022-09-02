import Foundation
import Combine
import CombineExt

import WeakMapTable

private enum MapTables {
    static let cancellables = WeakMapTable<AnyObject, Set<AnyCancellable>>()
    static let currentState = WeakMapTable<AnyObject, Any>()
    static let action = WeakMapTable<AnyObject, AnyObject>()
    static let state = WeakMapTable<AnyObject, AnyObject>()
}

public protocol Reactor: AnyObject {
    associatedtype Action
    associatedtype Mutation = Action
    associatedtype State

    var action: PassthroughSubject<Action, Never> { get }

    var initialState: State { get }
    var currentState: State { get }

    var state: any Publisher<State, Never> { get }

    func transform(action: any Publisher<Action, Never>) -> any Publisher<Action, Never>
    func mutate(action: Action) -> any Publisher<Mutation, Never>
    func transform(mutation: any Publisher<Mutation, Never>) -> any Publisher<Mutation, Never>
    func reduce(state: State, mutation: Mutation) -> State
    func transform(state: any Publisher<State, Never>) -> any Publisher<State, Never>
}

// MARK: - Default Implementations
extension Reactor {
    private var _action: PassthroughSubject<Action, Never> {
        MapTables.action.forceCastedValue(forKey: self, default: .init())
    }

    public var action: PassthroughSubject<Action, Never> {
        _ = _state

        return _action
    }

    public internal(set) var currentState: State {
        get { MapTables.currentState.forceCastedValue(forKey: self, default: initialState) }
        set { MapTables.currentState.setValue(newValue, forKey: self) }
    }

    private var _state: any Publisher<State, Never> {
        MapTables.state.forceCastedValue(forKey: self, default: createStateStream())
    }

    public var state: any Publisher<State, Never> {
        _state
    }

    fileprivate var cancellables: Set<AnyCancellable> {
        get { MapTables.cancellables.value(forKey: self, default: .init()) }
        set { MapTables.cancellables.setValue(newValue, forKey: self) }
    }

    public var scheduler: ImmediateScheduler {
        return ImmediateScheduler.shared
    }

    public func createStateStream() -> any Publisher<State, Never> {
        let replaySubject = ReplaySubject<State, Never>(bufferSize: 1)

        let action = _action
            .receive(on: scheduler)

        let mutation = transform(action: action)
            .eraseToAnyPublisher()
            .flatMap { [weak controller = self] action -> AnyPublisher<Mutation, Never> in
                guard let controller = controller else {
                    return Empty().eraseToAnyPublisher()
                }

                return controller.mutate(action: action).eraseToAnyPublisher()
            }

        let state = transform(mutation: mutation).eraseToAnyPublisher()
            .scan(initialState) { [weak controller = self] (state, mutation) -> State in
                guard let controller = controller else {
                    return state
                }

                return controller.reduce(state: state, mutation: mutation)
            }
            .prepend(initialState)

        let transformedState = transform(state: state).eraseToAnyPublisher()
            .handleEvents(receiveOutput: { [weak controller = self] (state) in
                guard let controller = controller else {
                    return
                }

                controller.currentState = state
            })
            .multicast(subject: replaySubject)
            .autoconnect()

        transformedState.sink(receiveValue: { _ in}).store(in: &cancellables)

        return transformedState.eraseToAnyPublisher()
    }

    public func transform(action: any Publisher<Action, Never>) -> any Publisher<Action, Never> {
        action
    }

    public func mutate(action: Action) -> any Publisher<Mutation, Never> {
        Empty<Mutation, Never>()
    }

    public func transform(mutation: any Publisher<Mutation, Never>) -> any Publisher<Mutation, Never> {
        mutation
    }

    public func reduce(state: State, mutation: Mutation) -> State {
        state
    }

    public func transform(state: any Publisher<State, Never>) -> any Publisher<State, Never> {
        state
    }
}

extension Reactor where Action == Mutation {
    public func mutate(action: Action) -> any Publisher<Mutation, Never> {
        Just(action).eraseToAnyPublisher()
    }
}
