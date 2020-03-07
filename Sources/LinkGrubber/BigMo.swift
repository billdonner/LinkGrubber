//
//  ExportModel.swift
//  
//
//  Created by william donner on 3/6/20.
//

import Foundation
struct AnchorInfo:Codable {
    let t:String
    let l: String // not url, it might just be the path if the base_url is a prefix
    let o:Int
}
struct SmallMo:Codable{
    let title: String
    let refs: [AnchorInfo]
}
struct BigMo: Codable {
    let schema_version = "0.1.0"
    let date_generated = "\(Date())"
    let base_url:URL
    let filters:[String]
    let meetups:[SmallMo]
}
