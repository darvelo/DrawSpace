//
//  Drawing.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import RealmSwift

class Image: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var contentType: String = ""
    @objc dynamic var resourceUrl: String = ""
    @objc dynamic var smallUrl: String = ""
    @objc dynamic var mediumUrl: String = ""
    @objc dynamic var largeUrl: String = ""
    @objc dynamic var localUrl: String = ""
}

class Drawing: Object {
    enum UploadState: String {
        case sending
        case failed
        case success
    }
    
    @objc dynamic var id: Int = -1
    @objc dynamic var title = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var uploadState: String = UploadState.sending.rawValue
    @objc dynamic var image: Image?
}

extension Drawing {
    var localImageData: Data? {
        guard let imageLocalUrl = image?.localUrl,
            !imageLocalUrl.isEmpty,
            let url = URL(string: imageLocalUrl),
            let data = try? Data(contentsOf: url) else {
                return nil
        }
        
        return data
    }
}
