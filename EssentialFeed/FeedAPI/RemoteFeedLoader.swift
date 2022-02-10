//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 04/02/22.
//

import Foundation


public class RemoteFeedLoader: FeedLoader {

    private let url: URL
    private let client: HttpClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping(Result) -> Void){
        client.get(from: url) {[weak self] result in
            guard self != nil else {
                return
            }
            switch result {
            case let .success(data, response):
                completion(FeedItemsMapper.map(data: data, response: response))
            case .failuer(_):
                completion(.failuer(Error.connectivity))
            }
        }
    }
}


