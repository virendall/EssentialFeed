//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Virender Dall on 10/02/22.
//

import Foundation

public enum HTTPClientResult {
    case success( Data, HTTPURLResponse)
    case failuer(Error)
}

public protocol HttpClient {
    func get(from url: URL, completion: @escaping(HTTPClientResult) -> Void)
}
