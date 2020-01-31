//
//  lgexporter.swift
//  
//
//  Created by william donner on 1/9/20.
//

import Foundation


var csvOutputStream : FileHandlerOutputStream!
var jsonOutputStream : FileHandlerOutputStream!
var traceStream : FileHandlerOutputStream!
var consoleIO = ConsoleIO()


open class RecordExporter {
    private var first = true
    
    func makecsvheader( ) -> String {
        return  "Name,Artist,Album,SongURL,AlbumURL,CoverArtURL"
    }
    func mskecsvtrailer( ) -> String?  {
        return    nil
    }
    func makecsvrow(cont:CrawlBlock) -> String {
        
        func cleanItUp(_ r:CrawlBlock, f:(String)->(String)) -> String {
            let z =
            """
            \(f(r.name ?? "")),\(f(r.artist ?? "")),\(f(r.album ?? "")),\(f(r.songurl)),\(f(r.albumurl ?? "")),\(f(r.cover_art_url ?? ""))
            """
            return z
        }
        return  cleanItUp(cont, f:LinkGrubber.kleenex)
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
]
""")
    }
    func addRowToExportStream(cont:CrawlBlock) {
        
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
