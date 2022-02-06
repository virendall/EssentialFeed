//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 04/02/22.
//

import Foundation
public enum HTTPClientResult {
    case success( Data, HTTPURLResponse)
    case failuer(Error)
}
protocol HttpClient {
    func get(from url: URL, completion: @escaping(HTTPClientResult) -> Void)
}

class RemoteFeedLoader {
    private let url: URL
    private let client: HttpClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failuer(Error)
    }
    
    init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping(Result) -> Void){
        client.get(from: url) { result in
            switch result {
            case let .success(data, _):
                if let _ = try? JSONSerialization.jsonObject(with: data) {
                    completion(.success([]))
                } else {
                    completion(.failuer(.invalidData))
                }
            case .failuer(_):
                completion(.failuer(.connectivity))
            }
        }
    }
}


