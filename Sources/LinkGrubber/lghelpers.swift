//
//  ighelpers.swift
//  
//
//  Created by william donner on 1/9/20.
//

import Foundation
 
struct LinkGrubberHello {
    var text = "Hello, World!"
}

var csvOutputStream : FileHandlerOutputStream!
var jsonOutputStream : FileHandlerOutputStream!
var traceStream : FileHandlerOutputStream!
var consoleIO = ConsoleIO()

public typealias PageMakerFunc = (_ props:CustomPageProps,  _ links: [Fav] ) throws -> ()

public struct CustomPageProps {
    let isInternalPage: Bool
    let urlstr: String
    let title: String
    let tags: [String]
}
public protocol   FileSiteProt: class {
    var pathToContentDir : String { get set }
    var pathToResourcesDir: String { get set }
    var pathToOutputDir: String { get set }
    var matchingURLPrefix : String { get set }
    var specialFolderPaths: [String]{ get set }
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

final class KrawlingInfo:NSObject {
 
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
    
    override init( ) {
        super.init()
        reset()
    }
}

open class LinkGrubberStats:Codable {
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
