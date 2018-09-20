//
//  Album.swift
//  Project 10 Music Album
//
//  Created by Chris on 15/9/2018.
//  Copyright © 2018 Chris. All rights reserved.
//

import Foundation

struct Album: Codable, Hashable{
    var artist: String
    var coverUrl: String
    var genre: String
    var title: String
    var year: String
}
