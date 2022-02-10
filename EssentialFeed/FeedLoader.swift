//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 04/02/22.
//

import Foundation
public enum LoadFeedResult {
    case success([FeedItem])
    case failuer(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping(LoadFeedResult) -> Void)
}
