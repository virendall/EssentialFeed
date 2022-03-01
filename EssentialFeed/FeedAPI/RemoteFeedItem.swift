//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Virender Dall on 01/03/22.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
