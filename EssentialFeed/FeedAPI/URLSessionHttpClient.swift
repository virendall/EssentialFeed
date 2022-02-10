//
//  URLSessionHttpClient.swift
//  EssentialFeed
//
//  Created by Virender Dall on 10/02/22.
//

import Foundation

public class URLSessionHTTPClient: HttpClient {
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct Unimplemented: Error{}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failuer(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failuer(Unimplemented()))
            }
        }.resume()
    }
}
