//
//  File.swift
//  
//
//  Created by william donner on 1/12/20.
//

import Foundation

// main entry point for public Linkgrubber.grub() call

fileprivate class KrawlStream : NSObject {
    
    var roots: [RootStart]
    var logLevel:LoggingLevel
    var transformer:Transformer
    var crawlStats:KrawlingInfo
    var pageMakerFunc: PageMakerFunc
    var lgFuncs:LgFuncs
    
    required   init (roots:[RootStart],
                     transformer:Transformer,
                     pageMakerFunc: @escaping PageMakerFunc,
                     lgFuncs:LgFuncs,
                     csvoutPath:LocalFilePath,
                     jsonoutPath:LocalFilePath,
                     logLevel:LoggingLevel) {
        
        self.transformer = transformer
        self.roots = roots
        self.lgFuncs = lgFuncs
        self.logLevel = logLevel
        self.crawlStats = KrawlingInfo()
        self.pageMakerFunc = pageMakerFunc
        //bootstrapExportDir()
        //
        do {
            // Some of the APIs that we use below are available in macOS 10.13 and above.
            guard #available(macOS 10.13, *) else {
                consoleIO.writeMessage("need at least 10.13",to:.error)
                exit(0)
            }
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
                        finally:@escaping ReturnsGrubberStats) {
        
        do {
            let _ = try OuterCrawler (roots: roots,transformer:transformer, pageMakerFunc: pageMakerFunc,
                                      loggingLevel: loggingLevel, lgFuncs: lgFuncs )
            { crawlResult in
                // here we are done, reflect it back upstream
                // print(crawlResult)
                // now here must unwind back to original caller
                finally(crawlResult)
            }
        }
        catch {
            invalidCommand(444);exit(0)
        }
    }
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
    
//    private var pageMakerFunc:PageMakerFunc
//
     public init( ) {
 
     }
    
    private var recordExporter =  RecordExporter()
    
    public  func grub(
                      roots:[RootStart],
                      opath:String,
                      params: FileSiteProt,
                      logLevel:LoggingLevel,
                      pageMakerFunc : @escaping PageMakerFunc,
                      lgFuncs : LgFuncs,
                      finally:@escaping ReturnsGrubberStats) throws {
        
        guard let fixedPath = URL(string:opath)?.deletingPathExtension().absoluteString
            else {  fatalError("cant fix outpath") }
        
        let transformer =  Transformer(recordExporter:recordExporter,
                               fsProt: params,
                               lgFuncs:  lgFuncs)
        
        let rm = KrawlStream(roots:roots,
                             transformer:transformer,
                               pageMakerFunc:pageMakerFunc,
                             lgFuncs: lgFuncs ,// transformer
          
            csvoutPath: LocalFilePath(fixedPath+".csv"),
            jsonoutPath: LocalFilePath(fixedPath+".json"),
            logLevel: logLevel)// krawlstream
        
        rm.startCrawling( roots:roots,loggingLevel: logLevel,finally:finally )
    }
}
