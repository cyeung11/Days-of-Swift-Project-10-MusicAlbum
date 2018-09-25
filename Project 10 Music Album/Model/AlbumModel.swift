//
//  AlbumModel.swift
//  Project 10 Music Album
//
//  Created by Chris on 15/9/2018.
//  Copyright © 2018 Chris. All rights reserved.
//

import Foundation

struct AlbumModel {
    var albums: [Album]?

    init() {
        let savedAlbums = FileHelper.default.read(fileName: "albums", as: [Album].self, fromCache: false)
        if let savedAlbums = savedAlbums{
            albums = savedAlbums
        } else if let url = Bundle.main.url(forResource: "albums", withExtension: "json"), let data = try? Data(contentsOf: url){
            albums = try? JSONDecoder().decode([Album].self, from: data)
        }
    }
    
    var count: Int {
        if let albums = albums{
            return albums.count
        } else {
            return 0
        }
    }
}
