//
//  DrawingsNetworkLayer.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import Alamofire
import Reachability

enum ResponseError: Error {
    case invalidJsonShape
}

class DrawingsNetworkLayer {
    
    // MARK: Typealiases
    
    typealias FetchedDrawing = Dictionary<String, Any>
    typealias FetchedDrawings = Array<FetchedDrawing>
    typealias FetchDrawingsResult = Result<FetchedDrawings, AFError>
    typealias CreateDrawingResult = Result<FetchedDrawing, AFError>

    // MARK: Private Properties
    
    private let sessionManager: Alamofire.Session
    
    private let photoUrl = ""
    private let drawingUrl = ""
    
    // MARK: Initialization
    
    init(sessionManager: Alamofire.Session) {
        self.sessionManager = sessionManager
    }
    
    // MARK: Public Methods
    
    func upload(data: Data, completion: @escaping (Result<Dictionary<String, Any>, AFError>) -> Void) {
        guard let url = URL(string: photoUrl) else { return }
        let headers: Alamofire.HTTPHeaders = [
            "Accept": "accept: application/json",
            "Content-Type": "multipart/form-data",
        ]
        
        let request = sessionManager.upload(multipartFormData: { (multipart) in
                                                multipart.append(data, withName: "file", fileName: "file.jpg", mimeType: "image/jpg")
                                            },
                                            to: url,
                                            usingThreshold: UInt64(),
                                            method: .post,
                                            headers: headers)
        
        request.responseJSON { (response) in
            switch response.result {
            case .success(let data):
                guard let json = data as? Dictionary<String, Any> else {
                    let err: AFError = .responseValidationFailed(reason: .customValidationFailed(error: ResponseError.invalidJsonShape))
                    completion(.failure(err))
                    return
                }
                print(data)
                completion(.success(json))
            case .failure(let err):
                print("Failed")
                completion(.failure(err))
            }
        }
    }
    
    func create(drawing: Drawing, completion: @escaping (CreateDrawingResult) -> Void) {
        if let data = drawing.localImageData {
            upload(data: data) { result in
                switch result {
                case .success(let json):
                    self.persist(drawing: drawing, imageId: json["id"] as? String, completion: completion)
                case .failure:
                    completion(result)
                }
            }
        } else {
            persist(drawing: drawing, imageId: nil, completion: completion)
        }
    }
    
    private func persist(drawing: Drawing, imageId: String?, completion: @escaping (CreateDrawingResult) -> Void) {
        guard let url = URL(string: drawingUrl) else { return }
        
        let headers: Alamofire.HTTPHeaders = [
            "Accept": "accept: application/json",
            "Content-Type": "application/json",
        ]
        var parameters: Alamofire.Parameters = [
            "title": drawing.title,
        ]
        
        if let imageId = imageId {
            parameters["image_id"] = imageId
        }
        
        let request = sessionManager.request(url,
                                             method: .post,
                                             parameters: parameters,
                                             encoding: Alamofire.JSONEncoding(),
                                             headers: headers)
        
        request.responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let result: CreateDrawingResult
                if let json = data as? FetchedDrawing, self.validate(drawing: json) {
                    print("persisted drawing JSON: \(json)")
                    result = .success(json)
                } else {
                    let err: AFError = .responseValidationFailed(reason: .customValidationFailed(error: ResponseError.invalidJsonShape))
                    result = .failure(err)
                }
                
                completion(result)
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func fetchDrawings(completion: @escaping (FetchDrawingsResult) -> Void) {
        guard let url = URL(string: drawingUrl) else {
            let err = AFError.invalidURL(url: drawingUrl)
            completion(.failure(err))
            return
        }

        let headers: Alamofire.HTTPHeaders = [
            "Accept": "accept: application/json",
        ]
        let request = sessionManager.request(url,
                                             method: .get,
                                             headers: headers)
        
        request.responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let result: FetchDrawingsResult
                
                if let json = data as? FetchedDrawings, json.allSatisfy({ self.validate(drawing: $0) }) {
                    result = .success(json)
                } else {
                    let err = AFError.responseValidationFailed(reason: .customValidationFailed(error: ResponseError.invalidJsonShape))
                    result = .failure(err)

                }

                completion(result)
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // MARK: Private Methods
    
    private func validate(drawing json: FetchedDrawing) -> Bool {
        guard let _ = json["id"] as? Int,
            let _ = json["title"] as? String else {
                return false
        }
        
        return true
    }
}
