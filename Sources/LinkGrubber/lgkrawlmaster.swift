//
//  File.swift
//  
//
//  Created by william donner on 1/12/20.
//

import Foundation

// main entry point for public Linkgrubber.grub() call

  fileprivate class KrawlStream : NSObject {

      var config: Configable
      var logLevel:LoggingLevel
      var transformer:Transformer
      var crawlStats:CrawlStats
        var pageMakerFunc:MarkdownMakerSignature
 
      required   init (config:Configable, transformer:Transformer, pageMakerFunc:@escaping MarkdownMakerSignature,csvoutPath:LocalFilePath,jsonoutPath:LocalFilePath, logLevel:LoggingLevel) {
   
          self.transformer = transformer
                 self.pageMakerFunc = pageMakerFunc
          self.config = config
          self.logLevel = logLevel
          self.crawlStats = CrawlStats(transformer: self.transformer)
          bootstrapExportDir()
          
          do {
              // Some of the APIs that we use below are available in macOS 10.13 and above.
              guard #available(macOS 10.13, *) else {
                  consoleIO.writeMessage("need at least 10.13",to:.error)
                  exit(0)
              }
              let url = URL(fileURLWithPath:  csvoutPath.path,relativeTo: ExportDirectoryURL)
              try  "".write(to: url, atomically: true, encoding: .utf8)
              let fileHandle = try FileHandle(forWritingTo: url)
              csvOutputStream = FileHandlerOutputStream(fileHandle)
              
              let url2 = URL(fileURLWithPath:  jsonoutPath.path,relativeTo: ExportDirectoryURL)
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
      
      func startCrawling(  configURL:URL,loggingLevel:LoggingLevel,finally:@escaping ReturnsCrawlResults) {
          let (roots)  = self.config.load(url: configURL)
          
          do {
              let _ = try OuterCrawler (roots: roots,transformer:transformer,pageMakerFunc: pageMakerFunc,
                                         loggingLevel: loggingLevel )
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
    
    private var pageMakerFunc:MarkdownMakerSignature
   
    public init(pageMakerFunc:@escaping MarkdownMakerSignature) {
        self.pageMakerFunc = pageMakerFunc
    }
    
    private var recordExporter =  RecordExporter()

    public  func grub(name:String,configURL: URL, opath:String,
                      bandSiteParams: BandSiteProt,specialFolderPaths: [String], logLevel:LoggingLevel, finally:@escaping ReturnsCrawlResults) throws {
     
        guard let fixedPath = URL(string:opath)?.deletingPathExtension().absoluteString
            else {  fatalError("cant fix outpath") }

        let rm = KrawlStream(config:ConfigurationProcessor(),
                             transformer: Transformer(artist: name,
                                                      recordExporter:recordExporter,bandSiteProt: bandSiteParams,    specialFolderPaths: specialFolderPaths,
                                                      defaultArtUrl: "booly"),
                                                    pageMakerFunc: self.pageMakerFunc,
                                csvoutPath: LocalFilePath(fixedPath+".csv"),
                                jsonoutPath: LocalFilePath(fixedPath+".json"),
                                logLevel: logLevel )
        rm.startCrawling(  configURL:configURL,loggingLevel: logLevel,finally:finally )
    }
}
