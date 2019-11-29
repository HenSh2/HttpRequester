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
    case ApplicationJson = "application/json"
    case MultiPart = "multipart/form-data"
    case None = ""
}

public class HttpRequester {
    
    private init() {
        self.sessionConfiguration.timeoutIntervalForRequest = 20.0
        self.sessionConfiguration.timeoutIntervalForResource = 20.0
    }
    
    public typealias HttpRequesterCompletion = (_ data: Data, _ statusCode: Int, _ error: Bool) -> ()
    
    public static let shared: HttpRequester = HttpRequester()
    
    private let sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
    
    public func request(urlString: String,
                        httpMethod: HttpMethod = HttpMethod.GET,
                        headerType: HeaderField = .ApplicationJson,
                        headerParams: [String: String]? = nil,
                        bodyParams: [String: Any?]? = nil,
                        queryParams: [String: String]? = nil,
                        completion: @escaping HttpRequesterCompletion) {
        self.request(urlString: urlString,
                     httpMethod: httpMethod,
                     headerType: headerType,
                     headerParams: headerParams,
                     bodyParams: bodyParams,
                     queryParams: queryParams,
                     dataArray: nil,
                     namesArray: nil) { (data, statusCode, error) in
                        completion(data, statusCode, error)
        }
    }
    
    public func uploadMultiPart(urlString: String,
                                httpMethod: HttpMethod = HttpMethod.POST,
                                headerParams: [String: String]? = nil,
                                bodyParams: [String: Any?]? = nil,
                                queryParams: [String: String]? = nil,
                                name: String,
                                dataArray: [Data?]? = nil,
                                namesArray: [String]? = nil,
                                completion: @escaping HttpRequesterCompletion) {
        self.request(urlString: urlString,
                     httpMethod: httpMethod,
                     headerType: .MultiPart,
                     headerParams: headerParams,
                     bodyParams: bodyParams,
                     queryParams: queryParams,
                     dataArray: dataArray,
                     namesArray: namesArray,
                     name: name) { (data, statusCode, error) in
                        completion(data, statusCode, error)
        }
    }
    
    private func request(urlString: String,
                         httpMethod: HttpMethod,
                         headerType: HeaderField,
                         headerParams: [String: String]?,
                         bodyParams: [String: Any?]?,
                         queryParams: [String: String]?,
                         dataArray: [Data?]? = nil,
                         namesArray: [String]? = nil,
                         name: String = "",
                         completion: @escaping HttpRequesterCompletion) {
        
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
            if headerType == .MultiPart {
                let boundaryId: String = "Boundary-\(UUID().uuidString)"
                request.setValue("multipart/form-data; boundary=\(boundaryId)", forHTTPHeaderField: "Content-Type")
                let body: Data = self.dataBody(bodyParams: bodyParams,
                                               name: name,
                                               data: dataArray,
                                               namesArray: namesArray,
                                               boundaryId: boundaryId)
                request.httpBody = body
            } else {
                let values = self.headerField(value: headerType)
                request.setValue(values["value"], forHTTPHeaderField: values["type"]!)
            }
        }
        
        //Check for vaild body params and add to request
        if let params = bodyParams, headerType != .MultiPart {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            } catch let bodyParamsError {
                debugPrint("Invalid Body Params --->>> \(bodyParamsError.localizedDescription)")
                return
            }
        }
        
        URLSession(configuration: self.sessionConfiguration).dataTask(with: request) { (data, response, error) in
            guard error != nil else {
                let statusCode: Int = (response as? HTTPURLResponse)?.statusCode ?? 0
                self.debugPrint("URL --->>> \(response?.url?.absoluteString ?? "response is nil"), statusCode --->>> \(statusCode)")
                guard let data = data else {
                    self.debugPrint("raw data is empty")
                    DispatchQueue.main.async {
                        completion(Data(), statusCode, false)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(data, statusCode, false)
                }
                return
            }
            self.debugPrint("URL --->>> \(response?.url?.absoluteString ?? "response is nil"), error --->>> \(error.debugDescription)")
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
    
    func dataBody(bodyParams: [String: Any?]?,
                  name: String,
                  data: [Data?]?,
                  namesArray: [String]?,
                  boundaryId: String) -> Data {
        guard let data = data else {
            self.debugPrint("can't create data body, data is empty")
            return Data()
        }
        
        let lineBreak: String = "\r\n"
        let contentDisposition: String = "Content-Disposition: form-data;"
        var body = Data()
        
        if let bParams = bodyParams as? [String: String] {
            //Add all body params as data
            for (key, value) in bParams {
                body.appendString("--\(boundaryId + lineBreak)")
                body.appendString("\(contentDisposition) name=\"\(key)\"\(lineBreak + lineBreak)")
                body.appendString("\(value + lineBreak)")
            }
        } else {
            if bodyParams != nil {
                self.debugPrint("provide only strings in body params --->>> [String: String]")
            } else {
                self.debugPrint("bodyParams --->>> nil")
            }
        }
        
        //Add data with boundary
        for (i, dat) in data.enumerated() {
            if let d = dat {
                body.appendString("--\(boundaryId + lineBreak)")
                body.appendString("\(contentDisposition) name=\"\(name)\"; filename=\(self.getFileName(index: i, namesArray: namesArray))\(lineBreak)")
                body.appendString("Content-Type: image/jpeg" + "\(lineBreak + lineBreak)")
                body.append(d)
                body.appendString(lineBreak)
            }
        }
        
        body.appendString("--\(boundaryId)--\(lineBreak)")
        
        return body
    }
    
    private func getFileName(index: Int, namesArray: [String]?) -> String {
        let imageName: String = "\"image"
        let jpegSuffix: String = ".jpeg\""
        guard let names = namesArray else {
            return imageName + jpegSuffix
        }
        return index < names.count ? "\"\(names[index])\(jpegSuffix)" : imageName + jpegSuffix
    }
    
}

extension HttpRequester {
    
    fileprivate func debugPrint(_ str: String = "") {
        //Print only in debug mode (ignore in release)
        #if DEBUG
        print(str)
        #endif
    }
    
}
