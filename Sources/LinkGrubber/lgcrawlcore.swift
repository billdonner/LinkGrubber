
//touch may 14 15:00
//  VeryCommon.swift
//  grabads
//
//  Created by william donner on 4/12/19.
//  Copyright © 2019 midnightrambler. All rights reserved.
//
//

import Foundation

import func Darwin.fputs
import var Darwin.stderr

public typealias  ReturnsGrubberStats = (LinkGrubberStats)->()
typealias ReturnsCrawlStats = (KrawlingInfo)->()
typealias ReturnsParseResults =  (ParseResults)->()
typealias ReturnsLinkElement = (LinkElement)->()

// nothing public here

// these really must be public, whereas the stuff below is only used within


// global, actually
enum CrawlState {
    case crawling
    case done
    case failed
}
public struct  RootStart : Codable  {
    public let name: String
    public    let urlstr: String
    
    public init(name:String, urlstr:String ){
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
       self.urlstr = urlstr
    }
}
// freestanding

// to pretty up for testing tweak the error string from cocoa into something json compatible (no duble quotes)
func safeError(error:Error) -> String {
    let matcher = """
"
""".trimmingCharacters(in: .whitespacesAndNewlines)
    let replacement = """
'
""".trimmingCharacters(in: .whitespacesAndNewlines)
    return  "\(error)".replacingOccurrences(of: matcher, with:replacement)
    
}


func makesafe(error:Error) -> String {
    let matcher = """
"
""".trimmingCharacters(in: .whitespacesAndNewlines)
    let replacement = """
'
""".trimmingCharacters(in: .whitespacesAndNewlines)
    return  "\(error)".replacingOccurrences(of: matcher, with:replacement)
    
}

func decomposePlayDate(_ playdate:String) -> (String,String,String) { // month day year ==> year month day
    let month = playdate.prefix(2)
    let year = playdate.suffix(2)
    let start = playdate.index(playdate.startIndex, offsetBy: 2)
    let end = playdate.index(playdate.endIndex, offsetBy: -2)
    let range = start..<end
    let day = playdate[range]
    return (String(year),String(month),String(day))
}


//from apple via khanalou - i improved this to add an exclusive task segment before going to the concurrent queue
final class LimitedWorker {
    private let serialQueue = DispatchQueue(label: "com.midnightrambler.serial.queue")
    private let concurrentQueue = DispatchQueue(label: "com.midnightrambler.concurrent.queue", attributes: .concurrent)
    private let semaphore: DispatchSemaphore
    
    init(limit: Int) {
        semaphore = DispatchSemaphore(value: limit)
    }
    
    func enqueue(withLock: @escaping () -> (),concurrently: @escaping () -> ()) {
        serialQueue.async(execute: {
            self.semaphore.wait()
            withLock()
            self.concurrentQueue.async(execute: {
                concurrently()
                self.semaphore.signal()
            })
        })
    }
}


enum ParseStatus:Equatable  {
    case failed(code:Int)
    case succeeded
}

private enum ScrapeTechnique {
    case forcedFail
    case normal //was kannlinks...
}
 

typealias PageScraperFunc = ( URL,String)->ParseResults?
 
// scraping is not  Specific to any 3rd party libraries, custom scraping in the custom package
 


typealias TraceFuncSig =  (String,String?,Bool,Bool) -> ()

public enum Linktype {
    case leaf
    case hyperlink
}

public struct LinkElement  {
    let title: String
    let href: URL?
    let linktype: Linktype
    
    var urlstr: String {
        if let url = href {
            return url.absoluteString
        }
        else {
            return "bad url"
        }
    }
    // when a LinkElement is creted, it tries to make a url from the supplied string
   public init(title:String,href:String,linktype:Linktype,relativeTo:URL?) {
        self.title = title; self.href=URL(string:href,relativeTo:relativeTo); self.linktype=linktype
    }
}

public struct Props : Codable,Hashable {
    var key: String
    var value: String
    public init(key:String,value:String) {
        self.key = key
        self.value = value
    }
}

//
//struct TestResultsBlock:Codable {
//    enum CodingKeys: String, CodingKey {
//        case crawlStats    = "crawl-stats"
//        case crawlerStarted     = "crawler-started"
//        case reportTitle = "report-title"
//        case status
//        //        case leafpoints
//        //        case rootcrawlpoints
//        case command
//    }
//    var status:Int = 0
//    var leafpoints:[String]? = []
//    var rootcrawlpoints:[String]? = []
//    var command:[String] = []
//    var reportTitle:String = ""
//    var crawlStats:LinkGrubberStats?
//    var crawlerStarted: String =  ""
//
//}
//func exitWith( _ code:Int, error:Error) {
//
//    func emitResultsAsTrace(_ fb: TestResultsBlock){//}, _ trace: TraceFuncSig) {
//        // convert to json and put the whole chunk out
//        do {
//            let enc = JSONEncoder()
//            enc.outputFormatting = .prettyPrinted
//            let data = try enc.encode(fb)
//            if let json = String(data:data,encoding:.utf8) {
//                // trace(json,nil,true,false)
//                print(json)
//            }
//        }
//        catch {
//            print("Could  not encode fullparseblock ", error)
//        }
//    }
//
//
//    var trb = TestResultsBlock()
//    trb.status = code
//    trb.reportTitle = "-- config couldnt open \(safeError(error: error))"
//    emitResultsAsTrace(trb)//, traceStream)
//    exit(0)
//}
