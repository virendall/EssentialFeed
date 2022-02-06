//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Virender Dall on 04/02/22.
//

import XCTest
@testable import EssentialFeed



class RemoteFeedLoaderTests: XCTestCase {
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load{_ in }
        sut.load{_ in }
        XCTAssertEqual(client.requestURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSut()
        expect(sut, withResult: .failuer(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201,300, 400,500]
        samples.enumerated().forEach { index, code in
            expect(sut, withResult: .failuer(.invalidData)) {
                client.complete(withStatusCode: 400,
                                data: Data(), at: index)
            }
        }
        
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSut()
        expect(sut, withResult: .failuer(.invalidData)) {
            let invalidJSON: Data = "Invalid Data".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSut()
        expect(sut, withResult: .success([])) {
            let emprtyJson = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emprtyJson)
        }
    }
    
    
    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let item1 = makeItem(id: UUID(), imageUrl: URL(string: "http://a-url.com")!)
        let item2 = makeItem(id: UUID(), imageUrl: URL(string: "http://a-another-url.com")!)
        
        let (sut, client) = makeSut()
        expect(sut, withResult: .success([item1.model, item2.model])) {
            let emprtyJson = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: emprtyJson)
        }
    }
    
    
    func test_load_doesNotDeliverResultAfterSutInstanceHasBeenDeallocated() {
        let client = HttpClientSpy();
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: URL(string: "https://a-url.com")!, client: client)
        var captureResult: [RemoteFeedLoader.Result] = []
        sut?.load { captureResult.append($0) }
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        XCTAssertTrue(captureResult.isEmpty)
        
    }
    // MARk: - Helpers
    private func makeSut(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }
    
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock {[weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
    
    
    private func expect(_ sut: RemoteFeedLoader, withResult result: RemoteFeedLoader.Result, when action:() -> Void, file: StaticString = #file,line: UInt = #line) {
        var captureResult: [RemoteFeedLoader.Result] = []
        sut.load { captureResult.append($0) }
        action()
        XCTAssertEqual(captureResult, [result], file: file, line: line)
    }
    
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageUrl: URL) -> (model: FeedItem, json:[String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageUrl: imageUrl)
        let json = [
            "id" : id.uuidString,
            "description" : description,
            "location": location,
            "image" : imageUrl.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value {
                acc[e.key] = value
            }
        }
        return(item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items" : items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private class HttpClientSpy: HttpClient {
        private var messages: [(url: URL, completion: (HTTPClientResult) -> Void)] = []
        
        
        var requestURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failuer(error))
        }
        
        func complete(withStatusCode code: Int, data: Data,  at index: Int = 0) {
            let tuple = messages[index]
            let response = HTTPURLResponse(url: tuple.url, statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}


/**
 {
 "items": [
 {
 "id": "a UUID",
 "description": "a description",
 "location": "a location",
 "image": "https://a-image.url",
 },
 {
 "id": "another UUID",
 "description": "another description",
 "image": "https://another-image.url"
 },
 {
 "id": "even another UUID",
 "location": "even another location",
 "image": "https://even-another-image.url"
 },
 {
 "id": "yet another UUID",
 "image": "https://yet-another-image.url"
 }
 ...
 ]
 }
 */