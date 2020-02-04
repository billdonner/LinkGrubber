//
//  File.swift
//  
//
//  Created by william donner on 2/4/20.
//
 
import Foundation

//MARK:- String Extractions for Parsing
extension String {
    func ranges(of string: String, options: CompareOptions = .literal) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.lowerBound < range.upperBound ? range.upperBound : index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    func slices(from: String, to: String) -> [Substring] {
        let pattern = "(?<=" + from + ").*?(?=" + to + ")"
        return ranges(of: pattern, options: .regularExpression) .map{ self[$0] }
    }
    func extractAnchors()-> [Substring] {
        self.slices(from: "href=\"", to: "\"")
    }
    func extractTitle()-> [Substring] {
         self.slices(from: "<title>", to: "</title>")
    }
}
