// 11.05.2020

import UIKit
import Combine

enum APIError {
    case noData
    case url
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No Data"

        case .url:
            return "Invalid URL"
        }
    }
}

struct APIResponse: Decodable {
    let url: URL
}

struct API {
    func getRandomImageURL() -> Future<URL, Error> {
        Future<URL, Error> { promise in
            guard let url = URL(string: "https://api.thecatapi.com/v1/images/search") else {
                let error: APIError = .url
                return promise(.failure(error))
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                do {
                    if let error = error {
                        throw error
                    }

                    guard let data = data else {
                        throw APIError.noData
                    }

                    let decoder = JSONDecoder()
                    let model = try autoreleasepool {
                        try decoder.decode([APIResponse].self, from: data)
                    }

                    guard let firstObject = model.first else {
                        throw APIError.noData
                    }

                    promise(.success(firstObject.url))

                } catch {
                    promise(.failure(error))
                }
            }.resume()
        }
    }

    func getImageData(from url: URL) -> Future<Data, Error> {
        Future<Data, Error> { promise in
            URLSession.shared.dataTask(with: url) { data, _, error in
                do {
                    if let error = error {
                        throw error
                    }

                    guard let data = data else {
                        throw APIError.noData
                    }

                    promise(.success(data))

                } catch {
                    promise(.failure(error))
                }
                
            }.resume()
        }
    }
}
