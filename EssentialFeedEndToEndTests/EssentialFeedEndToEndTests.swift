//
//  EssentialFeedEndToEndTests.swift
//  EssentialFeedEndToEndTests
//
//  Created by Virender Dall on 10/02/22.
//

import XCTest
import EssentialFeed

class EssentialFeedEndToEndTests: XCTestCase {

    func test_endToEndTestServerGetFeedResult_matchesFixedTestAccountData() {
        let url = URL(string: "https://www.essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url:url, client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(loader)
        let exp = expectation(description: "Wait for result")
        var receivedResult: FeedLoader.Result?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        switch receivedResult {
        case let .success(items):
            XCTAssertEqual(8, items.count)
        default:
            XCTFail("Expected successfull result but get \(String(describing: receivedResult))")
        }
    }

}
