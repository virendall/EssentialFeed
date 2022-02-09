//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Virender Dall on 06/02/22.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct Unimplemented: Error{}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failuer(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failuer(Unimplemented()))
            }
        }.resume()
    }
}


class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = URL(string: "http://any-url.com")!
        var urlRequests: [URLRequest] = []
        
        URLProtocolStub.observeRequests { request in
            urlRequests.append(request)
        }
        
        let exp = expectation(description: "Waiting for request")
        makeSut().get(from: url) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(urlRequests.count, 1)
        XCTAssertEqual(urlRequests[0].url, url)
        XCTAssertEqual("GET", urlRequests[0].httpMethod)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        let receivedError = resultErrorFor(data: nil, response: nil, error: error) as NSError?
        XCTAssertEqual(receivedError?.code, error.code)
        XCTAssertEqual(receivedError?.domain, error.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidCases() {
        let nonHttpURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHttpURLResponse = anyHttpURLResponse()
        let anyData = anyData()
        let anyError = NSError(domain: "Any Error", code: 0, userInfo: nil)
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHttpURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHttpURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHttpURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHttpURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHttpURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHttpURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedOnHttpURlResponseWithData() {
        let expectedResponse = anyHttpURLResponse()
        let expectedData = anyData()
        
        let response = resultValuesFor(data: expectedData, response: expectedResponse, error: nil)
        
        
        XCTAssertEqual(response?.data, expectedData)
        XCTAssertEqual(response?.response?.statusCode, expectedResponse.statusCode)
        XCTAssertEqual(response?.response?.url, expectedResponse.url)
        
    }
    
    func test_getFromURL_succeedOnHttpURlResponseWithEmptyData() {
        let expectedResponse = anyHttpURLResponse()
        
        let response = resultValuesFor(data: nil, response: expectedResponse, error: nil)
        
        XCTAssertTrue(response?.data?.isEmpty ?? false)
        XCTAssertEqual(response?.response?.statusCode, expectedResponse.statusCode)
        XCTAssertEqual(response?.response?.url, expectedResponse.url)
        
    }
    
    // MARK: - Helpers
    private func makeSut(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut)
        return sut
    }
    
    private func resultErrorFor(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)
        switch result {
        case let .failuer(receivedError):
            return receivedError
        default:
            XCTFail("Expected failure, got \(result) instead")
        }
        return nil
    }
    
    private func resultValuesFor(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, file: StaticString = #file, line: UInt = #line) -> (data: Data?,response: HTTPURLResponse?)? {
        let result = resultFor(data: data, response: response, error: error)
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected Success, got \(result) instead")
        }
        return nil
    }
    
    private func resultFor(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSut(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var receivedValue: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedValue = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedValue
    }
    
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func anyHttpURLResponse() -> HTTPURLResponse { HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)! }
    private func anyData() -> Data { "Any data".data(using: .utf8)! }
    
    private class URLProtocolStub: URLProtocol {
        
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping ((URLRequest) -> Void)) {
            requestObserver = observer
        }
        
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        
        
        override func startLoading() {
            if let observer = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                observer(request)
                return
            }
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
