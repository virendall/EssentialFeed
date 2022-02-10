//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Virender Dall on 10/02/22.
//

import Foundation

class FeedItemsMapper {
    
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
            return .failuer(RemoteFeedLoader.Error.invalidData)
        }
        return .success(result.feed)
    }
    
}

