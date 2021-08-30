// 11.05.2020

import UIKit
import Combine
import CombineReactor

enum Async<T> {
    case none
    case loading
    case success(T)
    case error(Error)
}

extension Async {
    var isLoading: Bool {
        guard case .loading = self else {
            return false
        }

        return true
    }

    var result: T? {
        guard case .success(let result) = self else {
            return nil
        }

        return result
    }

    var error: Error? {
        guard case .error(let error) = self else {
            return nil
        }

        return error
    }
}

class ViewReactor: Reactor {
    enum Action {
        case reload
    }

    enum Mutation {
        case setImage(Async<UIImage?>)
    }

    struct State {
        var image: Async<UIImage?> = .none
    }

    let initialState = State()

    func mutate(action: Action) -> AnyPublisher<Mutation, Never> {
        switch action {
        case .reload:
            return reload()
        }
    }

    func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        action.prepend(.reload)
            .eraseToAnyPublisher()
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setImage(let image):
            newState.image = image
        }

        return newState
    }
}

extension ViewReactor {
    private func reload() -> AnyPublisher<Mutation, Never> {
        return API().getRandomImageURL()
            .flatMap { url in
                API().getImageData(from: url)
            }
            .map { data in
                let image = UIImage(data: data)
                return .success(image)
            }
            .prepend(.loading)
            .catch { error in
                .error(error)
            }
            .map { request in
                .setImage(request)
            }
            .eraseToAnyPublisher()
    }
}

extension ViewReactor {
    var isLoading: AnyPublisher<Bool, Never> {
        state
            .map(\.image)
            .map(\.isLoading)
            .eraseToAnyPublisher()
    }

    var error: AnyPublisher<Error, Never> {
        state
            .map(\.image)
            .compactMap(\.error)
            .eraseToAnyPublisher()
    }

    var result: AnyPublisher<UIImage?, Never> {
        state
            .map(\.image)
            .compactMap(\.result)
            .eraseToAnyPublisher()
    }
}
