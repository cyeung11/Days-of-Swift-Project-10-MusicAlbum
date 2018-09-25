//
//  FileHelper.swift
//  Project 10 Music Album
//
//  Created by Chris on 25/9/2018.
//  Copyright © 2018 Chris. All rights reserved.
//

import Foundation

class FileHelper {
    
    private static var SINGLETON: FileHelper?
    
    static var `default`: FileHelper{
        if SINGLETON == nil{
            SINGLETON = FileHelper()
        }
        return SINGLETON!
    }
    
    private let cacheURL: URL
    private let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init() {
        url = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)!
        cacheURL = (FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)!
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }
    
    func save<T: Encodable>(file: T, withName name: String, asCache: Bool)  {
        
        let fileURL = (asCache ?cacheURL :url).appendingPathComponent(name, isDirectory: false)
        
        do {
            
            if file is Data{
                let data = file as! Data
                try data.write(to: fileURL, options: .atomic)
            } else {
                let data = try encoder.encode(file)
                try data.write(to: fileURL, options: .atomic)
            }
            
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func read<T: Decodable>(fileName: String, as fileType: T.Type, fromCache: Bool) -> T? {
        let fileURL = (fromCache ?cacheURL :url).appendingPathComponent(fileName, isDirectory: false)
    
        if !FileManager.default.fileExists(atPath: fileURL.path){
            return nil
        }
        
        if let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe){
            if fileType is Data.Type{
                return data as? T
            } else if let file = try? decoder.decode(fileType, from: data){
                return file
            }
        }
        
        return nil
    }
}
