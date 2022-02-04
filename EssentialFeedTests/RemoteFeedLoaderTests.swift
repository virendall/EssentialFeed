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
        
        var captureErrors: [RemoteFeedLoader.Error] = []
        sut.load { captureErrors.append($0)}
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        XCTAssertEqual(captureErrors, [.connectivity])
    }
    
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        let (sut, client) = makeSut()
        let samples = [199, 201,300, 400,500]
        samples.enumerated().forEach { index, code in
            
            var captureErrors: [RemoteFeedLoader.Error] = []
            
            sut.load { captureErrors.append($0)}
            
            client.complete(withStatusCode: 400, at: index)
            
            XCTAssertEqual(captureErrors, [.invalidData])
        }
        
    }
    
    // MARk: - Helpers
    private func makeSut(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HttpClientSpy) {
        let client = HttpClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
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
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let tuple = messages[index]
            let response = HTTPURLResponse(url: tuple.url, statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(response))
        }
    }
}
