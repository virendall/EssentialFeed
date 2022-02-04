//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Virender Dall on 04/02/22.
//

import Foundation

protocol HttpClient {
    func get(from url: URL, completion: @escaping(Error) -> Void)
}

class RemoteFeedLoader {
    private let url: URL
    private let client: HttpClient
    
    public enum Error: Swift.Error {
        case connectivity
    }
    
    init(url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping(Error) -> Void = {_ in }){
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}


