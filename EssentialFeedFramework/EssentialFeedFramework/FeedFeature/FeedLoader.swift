//
//  FeedLoader.swift
//  EssentialFeedFramework
//
//  Created by Apple on 18/12/2021.
//

import Foundation


public protocol FeedLoader {
    
    typealias Result = Swift.Result<[FeedImage],Error>
    
    func load(completion: @escaping (Result)->Void)
}
