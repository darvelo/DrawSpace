//
//  DrawingsNetworkLayer.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import Alamofire
import Reachability

enum ResponseError: Error {
    case invalidJsonShape
    case invalidInternalUrl(path: String)
}

class DrawingsNetworkLayer {
    
    // MARK: Typealiases
    
    typealias FetchedDrawing = Dictionary<String, Any>
    typealias FetchedDrawings = Array<FetchedDrawing>
    typealias FetchDrawingsResult = Result<FetchedDrawings, AFError>
    typealias SaveDrawingResult = Result<FetchedDrawing, AFError>
    typealias DeleteDrawingsResult = Result<Any, AFError>

    // MARK: Private Properties
    
    private let sessionManager: Alamofire.Session
    private let iso8601Formatter = ISO8601DateFormatter()

    private lazy var imagesUrlPath = "\(DrawingsNetworkLayer.baseUrl)/image"
    private lazy var drawingsUrlPath = "\(DrawingsNetworkLayer.baseUrl)/drawings"

    // MARK: Public Properties

    static let baseUrl = "http://localhost:3000"

    // MARK: Initialization
    
    init(sessionManager: Alamofire.Session) {
        self.sessionManager = sessionManager
    }
    
    // MARK: Public Methods
    
    func uploadImage(data: Data, completion: @escaping (Result<Dictionary<String, Any>, AFError>) -> Void) {
        let urlPath = imagesUrlPath
        guard let url = URL(string: urlPath) else {
            completion(.failure(.createURLRequestFailed(error: ResponseError.invalidInternalUrl(path: urlPath))))
            return
        }

        let headers: Alamofire.HTTPHeaders = [
            "Accept": "accept: application/json",
            "Content-Type": "multipart/form-data",
        ]
        
        let request = sessionManager.upload(multipartFormData: { (multipart) in
                                                multipart.append(data, withName: "image", fileName: "image.jpg", mimeType: "image/jpg")
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

    func save(drawing: Drawing, isUpdate: Bool, completion: @escaping (SaveDrawingResult) -> Void) {
        guard let data = drawing.localImageData else {
            assertionFailure("Had no local image data to persist")
            return
        }

        uploadImage(data: data) { result in
            switch result {
            case .success(let json):
                self.persist(drawing: drawing, imageId: json["id"] as? String, imageUrl: json["url"] as? String, isUpdate: isUpdate, completion: completion)
            case .failure:
                completion(result)
            }
        }
    }

    func deleteAll(completion: @escaping (DeleteDrawingsResult) -> Void) {
        let urlPath = drawingsUrlPath
        guard let url = URL(string: urlPath) else {
            completion(.failure(.createURLRequestFailed(error: ResponseError.invalidInternalUrl(path: urlPath))))
            return
        }

        let request = sessionManager.request(url,
                                             method: .delete,
                                             encoding: Alamofire.JSONEncoding())

        request.response { (response) in
            guard let err = response.error else {
                completion(.success(()))
                return
            }

            completion(.failure(err))
        }
    }
    
    private func persist(drawing: Drawing, imageId: String?, imageUrl: String?, isUpdate: Bool, completion: @escaping (SaveDrawingResult) -> Void) {
        guard let url = URL(string: isUpdate ? "\(drawingsUrlPath)/\(drawing.id)": drawingsUrlPath) else { return }
        
        let headers: Alamofire.HTTPHeaders = [
            "Accept": "accept: application/json",
            "Content-Type": "application/json",
        ]
        var parameters: Alamofire.Parameters = [
            "createdAt": iso8601Formatter.string(from: drawing.createdAt),
            "drawingDurationSeconds": drawing.drawingDurationSeconds,
            "width": drawing.width,
            "height": drawing.height,
            "steps": drawing.steps.toJSON(),
        ]
        
        if let imageId = imageId {
            parameters["imageId"] = imageId
        }

        if let imageUrl = imageUrl {
            parameters["imageUrl"] = imageUrl
        }
        
        let request = sessionManager.request(url,
                                             method: isUpdate ? .put : .post,
                                             parameters: parameters,
                                             encoding: Alamofire.JSONEncoding(),
                                             headers: headers)
        
        request.responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let result: SaveDrawingResult
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
        guard let url = URL(string: drawingsUrlPath) else {
            let err = AFError.invalidURL(url: drawingsUrlPath)
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
            let _ = json["createdAt"] as? String,
            let _ = json["drawingDurationSeconds"] as? Double,
            let _ = json["width"] as? Double,
            let _ = json["height"] as? Double,
            let _ = json["imageId"] as? String?,
            let _ = json["imageUrl"] as? String?,
            let _ = json["steps"] as? Array<[String: Any]> else {
                return false
        }

        return true
    }
}
