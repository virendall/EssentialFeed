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
                client.complete(withStatusCode: 400, at: index)
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
            
             let emprtyJson = """
             {
                 "items" : []
             }
     """.data(using: .utf8)!
             client.complete(withStatusCode: 200, data: emprtyJson)
        }
    }
    
    
    // MARk: - Helpers
    private func makeSut(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, withResult result: RemoteFeedLoader.Result, when action:() -> Void, file: StaticString = #file,line: UInt = #line) {
        var captureErrors: [RemoteFeedLoader.Result] = []
        sut.load { captureErrors.append($0) }
        action()
        XCTAssertEqual(captureErrors, [result], file: file, line: line)
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
        
        func complete(withStatusCode code: Int, data: Data = Data(),  at index: Int = 0) {
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
