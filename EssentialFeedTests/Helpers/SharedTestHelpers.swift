//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Virender Dall on 01/03/22.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
