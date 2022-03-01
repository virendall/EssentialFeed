//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 01/03/22.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

