//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedFrameworkTests
//
//  Created by Apple on 18/12/2021.
//


//Load Feed Use Cases (happy path)
//Data URL  (covered)
//1. Execute "Load Feed Items" command with above data.(covered)
//2. System downloads data from the URL.(covered)
//3. Sysem validate downloaded data. (covered)
//4. System creates feed item from valid data. (covered)
//5. Systen delivers feed items. (covered)

//Invalid data - errors course (sad path)
//1. System delivers error. (covered)

//No connectivity - error course (sad path) (covered)


import XCTest

import EssentialFeedFramework

class RemoteFeedLoaderTest: XCTestCase {
    
    
    func test_init_doesNotRequestRequestDataFromURL()  {
        
        //Arrange or Given client and sut (system under test)
        
        
       let (_, client) = makeSUT()
        
        //Act or when , so far nothing
        
        //Assert or Then, the client would have no URL
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        
        let url = URL(string: "https://a-given-url.com")!
        //Arrange or Given client and sut (system under test)
        
        let (sut, client) = makeSUT(url: url)
        
        //Act or when we invoke sut.load()
        sut.load{ _ in }
       
        //then or Assert, then assert that a URL request was initiated in the client
        XCTAssertEqual(client.requestedURLs, [url])
    }
    func test_load_requestDataFromURLTwice() {
        
        let url = URL(string: "https://a-given-url.com")!
        //Arrange or Given client and sut (system under test)
        
        let (sut, client) = makeSUT(url: url)
        
        //Act or when we invoke sut.load()
        sut.load{ _ in }
        sut.load{ _ in }
        
        //then or Assert, then assert that a URL request was initiated in the client
        XCTAssertEqual(client.requestedURLs, [url, url])
        
    }
    func test_load_deliversErrorsOnClientError()  {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
             
             client.complete(with: clientError)
        })
        
    }
    func test_load_deliversErrorsOnNon200HTTPResponse()  {
        let (sut, client) = makeSUT()
        
        
        let samples = [199,201,300,400,500]
        
        samples.enumerated().forEach{
            index, code in
            
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
            
        }
    
    }
    
    func test_load_deliversErrorsOn200ResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data( _ : "InvalidJson".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
            
        })
        
    }
    func test_load_delivers_NoItemsOn200HTTPResponseWithEmptyJSONList()  {

        let (sut, client) = makeSUT()
        
        expect(sut,toCompleteWith: .success([]), when:{
            let emptyListJSON = makeItemsJSON([])
            
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
        
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems(){
        
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!)
        
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location:"a location",
            imageURL: URL(string: "http://another-url.com")!)
        
        
        
        let items = [item1.model, item2.model]
        
        expect(sut,toCompleteWith: .success(items), when:{
            let json = makeItemsJSON([item1.json, item2.json])
            
            client.complete(withStatusCode: 200, data: json)
        })
        
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated()  {
        let url = URL(string: "http:any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load { capturedResult.append($0)}
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResult.isEmpty)
    }
    
    //MARK:  Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line)->(sut: RemoteFeedLoader,client : HTTPClientSpy ) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        return (sut, client)
    }
    
    /**
        By using factory methods in the test scope, we also prevent our test methods from breaking in the future if we ever decide to change the production types again!
     */
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private func makeItemsJSON(_ items:[[String:Any]])->Data {
        let json = ["items" : items]
       return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeItem(id: UUID, description:String? = nil,
                          location: String? = nil, imageURL : URL)-> (model:FeedImage, json:[String : Any]){
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location" : location,
            "image" : imageURL.absoluteString
        ].compactMapValues { $0 }
         // we used that to remove nil, in swift 5 compact Map value does the same , but we don't have yet that
        
        return (item, json)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith expectedResult: RemoteFeedLoader.Result, when
                            action: ()->Void, file: StaticString = #file, line: UInt = #line){
        
        
        let exp = expectation(description: "wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems),.success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file:file,line:line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file:file,line:line)
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead",file: file,line: line)
            
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
        
        
    }
    
    
    
    private class HTTPClientSpy: HTTPClient {
        
        private var messages = [(url: URL, completion: (HTTPClient.Result)-> Void)]()
        
        var requestedURLs : [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            
            messages.append((url, completion))
        }
        func complete(with error: Error, at index: Int = 0)  {
            messages[index].completion(.failure(error))
        }
        func complete(withStatusCode code: Int, data : Data, at index: Int = 0)  {
            
            let response = HTTPURLResponse(url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            
            messages[index].completion(.success((data,response)))
        }
    }
    
    

    
    
}
