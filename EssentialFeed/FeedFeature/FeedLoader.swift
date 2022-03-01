//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 01/03/22.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>
    func load(completion: @escaping (Result) -> Void)
}

