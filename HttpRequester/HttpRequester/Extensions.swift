//
//  Extensions.swift
//  HttpRequester
//
//  Created by Hen Shabat on 05/05/2019.
//  Copyright © 2019 Hen Shabat. All rights reserved.
//

extension Data {
    
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
}
