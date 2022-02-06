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
        client.get(from: url) {[weak self] result in
            guard self != nil else {
                return
            }
            switch result {
            case let .success(data, response):
                completion(RemoteFeedMapper.map(data: data, response: response))
            case .failuer(_):
                completion(.failuer(.connectivity))
            }
        }
    }
}

class RemoteFeedMapper {
    
    struct Root: Decodable {
        let items: [Items]
        var feed: [FeedItem] {
            items.map { $0.feed }
        }
    }
    
    struct Items: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var feed: FeedItem {
            return FeedItem(
                id: self.id, description: self.description, location: self.location, imageUrl: self.image
            )
        }
    }
    
    static func map(data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == 200,
              let result = try? JSONDecoder().decode(Root.self, from: data)
        else {
            return .failuer(.invalidData)
        }
        return .success(result.feed)
    }
    
}


