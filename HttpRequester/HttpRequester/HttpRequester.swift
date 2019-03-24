//
//  HttpRequester.swift
//  HttpRequester
//
//  Created by Hen Shabat on 03/03/2019.
//  Copyright © 2019 Hen Shabat. All rights reserved.
//

import Foundation

public enum HttpMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
    case PATCH = "PATCH"
}

public enum HeaderField: String {
    case ApplicationJson = "Application/json"
    case None = ""
}

public class HttpRequester {
    
    private init() {
        self.sessionConfiguration.timeoutIntervalForRequest = 20.0
        self.sessionConfiguration.timeoutIntervalForResource = 20.0
    }
    
    public static let shared: HttpRequester = HttpRequester()
    
    private let sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
    
    public func request(urlString: String, httpMethod: HttpMethod = HttpMethod.GET,
                         headerType: HeaderField = .ApplicationJson,
                         headerParams: [String: String]? = nil,
                         bodyParams: [String: Any]? = nil,
                         queryParams: [String: String]? = nil,
                         completion: @escaping (_ data: Data, _ statusCode: Int, _ error: Bool) -> ()) {
        
        //Check for vaild main url
        guard var mainURL = URL(string: urlString) else {
            debugPrint("Invalid URL --->>> \(urlString)")
            return
        }
        
        //Check for vaild url with all querey params
        if let params = queryParams {
            let URLStringWithQuereyParams: String = mainURL.absoluteString + self.quereyParamsForUrl(params: params)
            guard let url = URL(string: URLStringWithQuereyParams) else {
                debugPrint("Invalid URL With Query Params --->>> \(URLStringWithQuereyParams)")
                return
            }
            mainURL = url
        }
        
        //Init the request and add header params if needed
        var request = URLRequest(url: mainURL)
        request.httpMethod = httpMethod.rawValue
        request.allHTTPHeaderFields = headerParams
        
        //Init Content-Type
        if headerType != .None {
            let values = self.headerField(value: headerType)
            request.setValue(values["value"], forHTTPHeaderField: values["type"]!)
        }
        
        //Check for vaild body params and add to request
        if let params = bodyParams {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            } catch let bodyParamsError {
                debugPrint("Invalid Body Params --->>> \(bodyParamsError.localizedDescription)")
                return
            }
        }
        
        URLSession(configuration: self.sessionConfiguration).dataTask(with: request) { (data, response, error) in
            guard error != nil else {
                let statusCode = (response as! HTTPURLResponse).statusCode
                self.debugPrint("HttpMethod = \(httpMethod.rawValue), URL --->>> \(response?.url?.absoluteString ?? ""), statusCode --->>> \(statusCode)")
                guard let data = data else {
                    self.debugPrint("raw data is empty")
                    completion(Data(), statusCode, false)
                    return
                }
                completion(data, statusCode, false)
                return
            }
            DispatchQueue.main.async {
                completion(Data(), 0, true)
            }
            }.resume()
    }
    
    private func headerField(value: HeaderField) -> [String: String] {
        var header: [String: String] = [String: String]()
        header["value"] = value.rawValue
        header["type"] = "Content-Type"
        return header
    }
    
    private func quereyParamsForUrl(params: [String: String]) -> String {
        //Add all querey params to one string
        var querey: String = "?"
        params.forEach { (key, value) in
            let encodingKey: String = key.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            let encodingValue: String = value.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            querey += "\(encodingKey)=\(encodingValue)&"
        }
        return String(querey.dropLast())
    }
    
    private func debugPrint(_ str: String) {
        //Print only in debug mode (ignore in release)
        #if DEBUG
        print("HttpRequester --->>> Print only in debug mode")
        print(str)
        #endif
    }
    
}

