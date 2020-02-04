
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

import HTMLExtractor
enum ParseStatus:Equatable  {
    case failed(code:Int)
    case succeeded
}

private enum ScrapeTechnique {
    case forcedFail
    case normal //was kannlinks...
}


typealias PageScraperFunc = (URL,String)->ParseResults?

typealias TraceFuncSig =  (String,String?,Bool,Bool) -> ()

typealias ReturnsCrawlStats = (KrawlingInfo)->()

typealias ReturnsParseResults =  (ParseResults)->()

typealias ReturnsLinkElement = (LinkElement)->()

// global, actually
enum CrawlState {
    case crawling
    case done
    case failed
}


//MARK:-  PUBLIC

public enum LoggingLevel {
    case none
    case verbose
}


public struct CustomPageProps {
    public var isInternalPage: Bool
    public var urlstr: String
    public var title: String
    public var tags: [String]
    
    public init (  isInternalPage: Bool,
                   urlstr: String,
                   title: String,
                   tags: [String]){
        self.isInternalPage = isInternalPage
        self.urlstr = urlstr
        self.title = title
        self.tags = tags
    }
}


open class LinkGrubberStats:Equatable {
    public static func == (lhs: LinkGrubberStats, rhs: LinkGrubberStats) -> Bool {
        lhs.added == rhs.added && lhs.count1 == lhs.count1 && lhs.count2 == lhs.count2
    }

    open var added:Int
    open var peak:Int
    open var elapsedSecs:Double
    open var secsPerCycle:Double
    open var count1: Int
    open var count2: Int
    open var status: Int
    
    public init (
        added:Int,
        peak:Int,
        elapsedSecs:Double,
        secsPerCycle:Double,
        count1: Int,
        count2: Int,
        status: Int){
        self.added = added
        self.peak = peak
        self.elapsedSecs = elapsedSecs
        self.secsPerCycle = secsPerCycle
        self.count1 = count1
        self.count2 = count2
        self.status = status
    }
    func describe () -> String {
        // if the internal status is not 200 then mark the log
        let happyface = self.status == 200 ? "🤲🏻" : "⬇️"
        
       return  "\n[LinkGrubber] scanned \(added) pages, added \(count1)  skipped \(count2)  -- \(String(format:"%5.2f",self.secsPerCycle*1000))ms per page \(happyface) \n"
    }
    
}


public struct  RootStart  {
    public let name: String
    public let urlstr: String
    
    public init(name:String = "", url:URL ){
        self.name = name=="" ? url.deletingPathExtension().lastPathComponent : name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.urlstr = url.absoluteString
    }
}
public class Fav {
    public let name: String
    public let url: String
    public  let comment: String
    public init (name:String = "",url:String = "",comment:String = "") {
        self.name = name
        self.url = url
        self.comment = comment
    }
}
public protocol LgFuncProts {
    func pageMakerFunc(_ props:CustomPageProps,
                       _ links: [Fav] ) throws -> ()
    func matchingFunc(_ u:URL) -> Bool
    func scrapeAndAbsorbFunc (theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock
    //this can be moved down to filetypeprots in bandsiste after build a func for incorporate parseblock
    func isImageExtensionFunc (_ s:String) -> Bool
}

public typealias IsFileExtensionFunc =  (String)->Bool
public typealias MatchingFunc =  (URL)->Bool
public typealias ScrapeAndAbsorbFunc = ( LgFuncProts, URL,String ) throws -> ScrapeAndAbsorbBlock
public typealias PageMakerFunc = (_ props:CustomPageProps,  _ links: [Fav] ) throws -> ()
public typealias ReturnsGrubberStats = (LinkGrubberStats)->()

//struct LgFuncs : LgFuncProts  {}

//MARK:- NON PUBLIC
struct OnePageGuts {
    let props : CustomPageProps
    let links : [Fav]
}

struct LocalFilePath {
    private(set) var p : String
    var path :String {
        return p//url.absoluteString
    }
    init(_ p:String){
        self.p = p
    }
}
struct URLFromString :Hashable {
    let  string : String
    let  url: URL?
    
    init(_ s:String ) {
        self.string = s
        self.url = URL(string:s)
    }
    
}

final class  CrawlBlock:Codable {
    // a place to stash page related things
    //these are the only elements moved into the output stream
    
    var name:String? = ""
    var artist:String? = ""
    var albumurl:String? = ""
    var songurl:String = ""
    var cover_art_url:String? = ""
    var album : String?  {
        if let alurl = albumurl {
            let blurl = alurl.hasSuffix("/") ? String( alurl.dropLast()  ) : alurl
            if  let aname = blurl.components(separatedBy: "/").last {
                return aname
            }
        }
        return albumurl
    }
}

final class KrawlingInfo:NSObject {
    
    var keyCounts:NSCountedSet!
    var goodurls :Set<URLFromString>!
    var badurls :Set<URLFromString>!
    func reset() {
        goodurls = Set<URLFromString>()
        badurls = Set<URLFromString>()
        keyCounts = NSCountedSet()
    }
    
    override init( ) {
        super.init()
        reset()
    }
    // dont let an item get on both lists
    func addBonusKey(_ s:String) {
        keyCounts.add(s)
    }
    func addStatsGoodCrawlRoot(urlstr:URLFromString) {
        let part  =  LinkGrubber.partFromUrlstr(urlstr)
        goodurls.insert(part )
        if badurls.contains(part)   { badurls.remove(part) }
    }
    func addStatsBadCrawlRoot(urlstr:URLFromString) {
        let part  =  LinkGrubber.partFromUrlstr(urlstr)
        if goodurls.contains(part)   { return }
        badurls.insert(part)
    }
}

struct ParseResults {
    let url : URL?
    let status : ParseStatus
    let pagetitle: String
    let links :  [LinkElement]
    let tags : [String]
    init(url:URL?,
         status:ParseStatus,
         pagetitle:String,
         links:[LinkElement],
         tags:[String]) {
        
        self.url = url
        self.status = status
        self.pagetitle = pagetitle
        self.links = links
        self.tags = tags
    }
}



// nothing public here

// these really must be public, whereas the stuff below is only used within




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

