//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedFrameworkTests
//
//  Created by Apple on 24/12/2021.
//

import XCTest

extension XCTestCase {
     func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line){
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance sould have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
