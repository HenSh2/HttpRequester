//
//  HttpRequester.swift
//  HttpRequester
//
//  Created by Hen Shabat on 03/03/2019.
//  Copyright © 2019 Hen Shabat. All rights reserved.
//

import Foundation

public class HttpRequester {
    
    private init() {}
    
    public static let shared: HttpRequester = HttpRequester()
    
    public func request() {
        print("request test")
    }
    
}

