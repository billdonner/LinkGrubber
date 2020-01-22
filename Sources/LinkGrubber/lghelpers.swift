//
//  ighelpers.swift
//  
//
//  Created by william donner on 1/9/20.
//

import Foundation
import Kanna

struct LinkGrubberHello {
    var text = "Hello, World!"
}

var csvOutputStream : FileHandlerOutputStream!
var jsonOutputStream : FileHandlerOutputStream!
var traceStream : FileHandlerOutputStream!
var consoleIO = ConsoleIO()

public typealias  ReturnsCrawlResults = (CrawlerStatsBlock)->()

public typealias MarkdownMakerSignature = ( Bool,   String,   String,   [String],   String, String, [Fav] ) throws -> ()


public protocol   BandSiteProt: class  {
    var venueShort : String { get set }
    var venueLong : String { get set }
    var crawlTags:[String] { get set }
    var pathToContentDir : String { get set }
    var pathToResourcesDir: String { get set }
    var pathToOutputDir: String { get set }
    var matchingURLPrefix : URL{ get set }
}



public enum LoggingLevel {
    case none
    case verbose
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

public func invalidCommand(_ code:Int) {
    print("""
        {"invalid-command":\(CommandLine.arguments), "status":\(code)}
        """)
    exit(0)
}
protocol Configable:class, Decodable {
    
    var comment:String {get set}
    func load (url:URL? ) -> ([RootStart])
}
open class CrawlerStatsBlock:Codable {
    enum CodingKeys: String, CodingKey {
        case elapsedSecs    = "elapsed-secs"
        case secsPerCycle     = "secs-percycle"
        case added
        case peak
        case count1
        case count2
        case status
    }
    open  var added:Int
    open var peak:Int
    open var elapsedSecs:Double
    open var secsPerCycle:Double
    open var count1: Int
    open  var count2: Int
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
    
}
struct ParseResults {
    let url : URL?
    let technique : ParseTechnique
    let status : ParseStatus
    
    let pagetitle: String
    let links :  [LinkElement]
    let props : [Props]
    let tags : [String]
    init(url:URL?,
         technique:ParseTechnique,
         status:ParseStatus,
         pagetitle:String,
         links:[LinkElement],
         props:[Props],
         tags:[String]) {
        
        self.url = url
        self.technique = technique
        self.status = status
        self.pagetitle = pagetitle
        self.links = links
        self.props = props
        self.tags = tags
    }
}


enum OutputType: String {
    case csv = "csv"
    case json = "json"
    case text = "text"
    case unknown
    
    init(value: String) {
        switch value {
        case "csv": self = .csv
        case "json": self = .json
        case "text": self = .text
        default: self = .unknown
        }
    }
}
/*
 
 build either csv or json export stream
 
 */

final class RecordExporter {
    private var first = true
    
    func makecsvheader( ) -> String {
        return  "Name,Artist,Album,SongURL,AlbumURL,CoverArtURL"
    }
    func mskecsvtrailer( ) -> String?  {
        return    "==CrawlingContext=="
    }
    func makecsvrow(cont:CrawlingElement) -> String {
        
        func cleanItUp(_ r:CrawlingElement, f:(String)->(String)) -> String {
            let z =
            """
            \(f(r.name ?? "")),\(f(r.artist ?? "")),\(f(r.album ?? "")),\(f(r.songurl)),\(f(r.albumurl ?? "")),\(f(r.cover_art_url ?? ""))
            """
            return z
        }
        return  cleanItUp(cont, f:kleenex)
    }
    
    
    private func emitToJSONStream(_ s:String) {
        print(s , to: &jsonOutputStream )// dont add extra
    }
    
    
    func addHeaderToExportStream( ) {
        print(makecsvheader(), to: &csvOutputStream )// dont add extra
        print("""
      [
    """ ,
              to: &jsonOutputStream )// dont add extra
    }
    func addTrailerToExportStream( ) {
        
        if let trailer =  mskecsvtrailer() {
            print(trailer , to: &csvOutputStream )
        }
        
        emitToJSONStream("""
}
""")
    }
    func addRowToExportStream(cont:CrawlingElement) {
        
        let stuff = makecsvrow(cont:cont )
        print(stuff , to: &csvOutputStream )
        
        
        let parts = stuff.components(separatedBy: ",")
        if first {
            emitToJSONStream("""
{
""")
        } else {
            emitToJSONStream("""
,{
""")
        }
        for (idx,part) in parts.enumerated() {
            emitToJSONStream("""
                "\(idx)":"\(part)"
                """)
            if idx == parts.count - 1 {
                emitToJSONStream("""
}
""")
            } else {
                emitToJSONStream(",")
            }
            
        }
        first =  false
    }
}


////////
///MARK- : STREAM IO STUFF

struct StderrOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}
public struct FileHandlerOutputStream: TextOutputStream {
    private let fileHandle: FileHandle
    let encoding: String.Encoding
    
    public init(_ fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        self.fileHandle = fileHandle
        self.encoding = encoding
    }
    
    mutating public func write(_ string: String) {
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }
}

final class ConsoleIO {
    
    enum StreamOutputType {
        case error
        case standard
    }
    
    func writeMessage(_ message: String, to: StreamOutputType = .standard, terminator: String = "\n") {
        switch to {
        case .standard:
            print("\(message)",terminator:terminator)
        case .error:
            fputs("\(message)\n", stderr)
        }
    }
}

final  class ConfigurationProcessor :Configable {
    
    enum CodingKeys: String, CodingKey {
        case comment
        case roots
    }
    
    var comment: String = "<no comment>"
    var roots:[String] = []
    var crawlStarts:[RootStart] = []
    
    
    func load (url:URL? = nil) -> ([RootStart]) {
        do {
            let obj =    try configLoader(url!)
            return (convertToRootStarts(obj: obj))
        }
        catch {
            invalidCommand(550); exit(0)
        }
    }
    func configLoader (_ configURL:URL) throws -> ConfigurationProcessor {
        do {
            let contents =  try Data.init(contentsOf: configURL)
            // inner
            do {
                let    obj = try JSONDecoder().decode(ConfigurationProcessor.self, from: contents)
                return obj
            }
            catch {
                exitWith(503,error: error)
            }
            // end inner
        }
        catch {
            exitWith(504,error: error)
        }// outer
        fatalError("should never get here")
    }
    func convertToRootStarts(obj:ConfigurationProcessor) -> ([RootStart]){
        var toots:[RootStart] = []
        for root in obj.roots{
            toots.append(RootStart(name:root.components(separatedBy: ".").last ?? "?root?",
                                   urlstr:root,
                                   technique: .parseTop))
        }
        crawlStarts = toots
        return (toots)
    }
}
// was runstats
final class CrawlStats:NSObject {
    
    var transformer:Transformer
    var keyCounts:NSCountedSet!
    var goodurls :Set<URLFromString>!
    var badurls :Set<URLFromString>!
    
    // dont let an item get on both lists
    func addBonusKey(_ s:String) {
        keyCounts.add(s)
    }
    func addStatsGoodCrawlRoot(urlstr:URLFromString) {
        let part  =  partFromUrlstr(urlstr)
        goodurls.insert(part )
        if badurls.contains(part)   { badurls.remove(part) }
    }
    func addStatsBadCrawlRoot(urlstr:URLFromString) {
        let part  =  partFromUrlstr(urlstr)
        if goodurls.contains(part)   { return }
        badurls.insert(part)
    }
    func reset() {
        goodurls = Set<URLFromString>()
        badurls = Set<URLFromString>()
        keyCounts = NSCountedSet()
    }
    init(transformer :Transformer) {
        self.transformer = transformer
        super.init()
        reset()
    }
}
