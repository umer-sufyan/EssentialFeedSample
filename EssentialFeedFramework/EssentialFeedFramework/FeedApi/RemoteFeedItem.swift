//
//  RemoteFeedItem.swift
//  EssentialFeedFramework
//
//  Created by Apple on 01/01/2022.
//

import Foundation

 struct RemoteFeedItem: Decodable {
     let id: UUID
     let description: String?
     let location: String?
     let image: URL
}
