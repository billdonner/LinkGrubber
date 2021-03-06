//
//  LinkGrubber.swift
//  
//
//  Created by william donner on 1/12/20.
//

import Foundation

// main entry point for public Linkgrubber.grub() call
struct LinkGrubberHello {
    var text = "LinkGrubber"
}

final public class LinkGrubber
{
    static func partFromUrlstr(_ urlstr:URLFromString) -> URLFromString {
        return urlstr//URLFromString(urlstr.url?.lastPathComponent ?? "partfromurlstr failure")
    }
    
    static func kleenURLString(_ url: URLFromString) -> URLFromString?{
        let original = url.string
        let newer = original.replacingOccurrences(of: "%20", with: "+")
        return URLFromString(newer)
    }
    
    static func kleenex(_ f:String)->String {
        return f.replacingOccurrences(of: ",", with: "!")
    }
    
    public init( ) {
        
    }
    
    private var recordExporter =  RecordExporter()
    private var krawlStream: KrawlStream? = nil  // keep this alive throughout a call to grub
    
    
    public  func grub(
        roots:[RootStart],
        opath:String, //
        logLevel:LoggingLevel,
        lgFuncs: LgFuncProts,
        finally:@escaping ReturnsGrubberStats) throws {
        
        let dir = URL(fileURLWithPath: opath,isDirectory: true)
        
//        guard let fixedPath = URL(string:opath)?.deletingPathExtension().absoluteString
//            else {  fatalError("cant fix outpath") }
        let transformer =  Transformer(recordExporter:recordExporter,   lgFuncs: lgFuncs, logLevel:logLevel )
        
        krawlStream = KrawlStream(roots:roots,
                             transformer:transformer,
                             lgFuncs: lgFuncs ,// transformerm
            csvoutPath:  dir.appendingPathExtension("csv"),
            jsonoutPath:  dir.appendingPathExtension("json"),
            logLevel: logLevel)// krawlstream
        guard let kstream = krawlStream else { fatalError("cant make krawlstream")}
        
        print("[LinkGrubber] streaming to \(dir)")
        let q = DispatchQueue( label:"background", qos:.background)
        q.async {
            do {
                try kstream.startCrawling( roots:roots,
                                      loggingLevel: logLevel,
                                      finally:finally )
            }
            catch {
                print("failed to startCrawling \(error)")
            }
        }
    }
}

fileprivate class KrawlStream : NSObject {
    
    var roots: [RootStart]
    var logLevel:LoggingLevel
    var transformer:Transformer
    var crawlStats:KrawlingInfo
    var lgFuncs:LgFuncProts
    var oc:OuterCrawler!
    
    required   init (roots:[RootStart],
                     transformer:Transformer,
                     lgFuncs:LgFuncProts,
                     csvoutPath:URL,
                     jsonoutPath:URL,
                     logLevel:LoggingLevel) {
        
        self.transformer = transformer
        self.roots = roots
        self.lgFuncs = lgFuncs
        self.logLevel = logLevel
        self.crawlStats = KrawlingInfo()
        //bootstrapExportDir()
        //
        do {
            // Some of the APIs that we use below are available in macOS 10.13 and above.
//            guard #available(macOS 10.13, *) else {
//                consoleIO.writeMessage("need at least 10.13",to:.error)
//                exit(0)
//            }
            let url = URL(fileURLWithPath:  csvoutPath.path)//.path,relativeTo: ExportDirectoryURL)
            try  "".write(to: url, atomically: true, encoding: .utf8)
            let fileHandle = try FileHandle(forWritingTo: url)
            csvOutputStream = FileHandlerOutputStream(fileHandle)
            
            let url2 = URL(fileURLWithPath:  jsonoutPath.path)//.path,relativeTo: ExportDirectoryURL)
            try  "".write(to: url2, atomically: true, encoding: .utf8)
            let fileHandle2 = try FileHandle(forWritingTo: url2)
            jsonOutputStream = FileHandlerOutputStream(fileHandle2)
            super.init()
            
        }
        catch {
            consoleIO.writeMessage("Could not initialize RunnableStream  \(error)",to:.error)
            exit(0)
        }
    }
    
    func startCrawling( roots:[RootStart],
                        loggingLevel:LoggingLevel,
                        finally:@escaping ReturnsGrubberStats) throws {
        
         oc =   OuterCrawler (transformer:transformer,
                                   lgFuncs: lgFuncs )
        
        try oc.startMeUp(roots,loggingLevel: loggingLevel)
        { crawlResult in
            // here we are done, reflect it back upstream
            print(crawlResult.describe())
            // now here must unwind back to original caller
            finally(crawlResult)
        }
        
    }
}
