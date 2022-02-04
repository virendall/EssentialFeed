//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 04/02/22.
//

import Foundation
public enum HTTPClientResult {
    case success(HTTPURLResponse)
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
    
    init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping(Error) -> Void){
        client.get(from: url) { result in
            switch result {
            case .success(let response):
                completion(.invalidData)
            case .failuer(let error):
                completion(.connectivity)
            }
        }
    }
}


