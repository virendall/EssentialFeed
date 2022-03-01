//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 01/03/22.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

