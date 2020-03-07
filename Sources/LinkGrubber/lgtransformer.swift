
//  Created by william donner on 4/19/19.
//

import Foundation


//MARK:- a Xenerator is just the title and parsed links from a web page


extension BigMo {
    
    func generate( ) throws -> String {
        var perfs:[SmallMo] = []
        for perf in meetups {
            if perf.refs.count > 0 {
            let filteredlinks:[AnchorInfo]  = perf.makeLinks(base_url,filters)
            if filteredlinks.count > 0 { // if no links, dont generate
                perfs.append( SmallMo(title: perf.title, refs: filteredlinks))
            }
            }
        }
        
          let encoder = JSONEncoder()
          if #available(OSX 10.15, *) {
              encoder.outputFormatting = [.withoutEscapingSlashes]//,.prettyPrinted]
          }
          let t = try encoder.encode(self)
          return   String(data:t, encoding:.utf8)!
      }
      
    func describe() -> String {
        return try! generate( )
    }
    func dump() throws {
        print("/********** BIGMO DUMP ************/")
        print(try generate( ))
        print("/********** end BIGMO DUMP ************/")
    }
}


extension SmallMo {
    
    func makeLinks(_ url: URL, _ filters:[String]) -> [AnchorInfo] {
        var filteredlinks:[AnchorInfo]=[]
        let nofilters = filters.count==0
        for alink in refs {
            let exta = alink.l.components(separatedBy: "/").last?.components(separatedBy: ".").last?.lowercased() ?? ""
            let nulink = alink.l.hasPrefix(title) ? String(alink.l.dropFirst(title.count)) : alink.l
          
       
                // even if no filters, require that an extension is present
                if exta != "" {
                    if nofilters { filteredlinks.append ( AnchorInfo(t:alink.t,
                                                                     l:nulink,
                                                                     o:filteredlinks.count+1))
                        
                    }
                    else {
                        // this is perhaps a little buggy and we should try to yse query parameters
                        if  filters.contains(exta) {
                            filteredlinks.append  ( AnchorInfo (t:alink.t,
                                                                l:nulink,
                                                                o:filteredlinks.count+1 ) )  }
                    }
                }
        }
       // guard filteredlinks.count != 0 else  { throw LinkGrubber.noLinks(title)}
        return filteredlinks
    }
    
}


public extension Array where Element == String  {
    func includes(_ f:Element)->Bool {
        self.firstIndex(of: f) != nil
    }
}

open class Transformer:NSObject {
    var lgFuncs:LgFuncProts
    var recordExporter : RecordExporter!
    var logLevel:LoggingLevel
    private var crawlblock = CrawlBlock()
    var firstTime = true
    
    public required  init( recordExporter:RecordExporter,    lgFuncs:LgFuncProts, logLevel:LoggingLevel) {
        
        self.lgFuncs = lgFuncs
        self.recordExporter = recordExporter
        self.logLevel = logLevel
        super.init()
    }
    deinit  {
        recordExporter.addTrailerToExportStream()
        // print("[crawler] finalized csv and json streams")
        //
      
        
        
    }
    
    
    func  incorporateParseResults(pr:ParseResults,imgurl:String="") throws -> OnePageGuts? {
        
        var mdlinks : [Fav] = []  // must reset each time !!
        // move the props into a record
        guard let url = pr.url else { fatalError() }
        
        for link in pr.links {
            if let linkref = link.href { // sometimes no href
            let href =  linkref.absoluteString //yikes
                let ext = linkref.pathExtension
            if !href.hasSuffix("/" ) && ext != "" {
                crawlblock.artist = "ABHD"
                crawlblock.albumurl = url.absoluteString
                crawlblock.name = link.title
                crawlblock.songurl = href
                crawlblock.track = "\(mdlinks.count + 1)"
                mdlinks.append(Fav(name:crawlblock.name ?? "??", url:crawlblock.songurl,comment:""))
                recordExporter.addRowToExportStream(cont: crawlblock)
            }
            }
        }
        
        // if we are writing md files for Publish
        if let aurl = crawlblock.albumurl {
            // figure out the coverarturl here, either take the default for the bandsite or take the first one in the mdlinks
//            for alink in mdlinks {
//                let x =  alink.url.components(separatedBy: ".").last ?? "fail"
////                if lgFuncs.isImageExtensionFunc(x) {
////                    crawlblock.track = alink.url
////                    break
////                }
//            }
            
            if crawlblock.track == "" {
                crawlblock.track = "99"
            }
            
            let props = CustomPageProps(isInternalPage: false,
                                        urlstr: aurl,
                                        title: crawlblock.name ?? "???",
                                        tags:  pr.tags)
        
            return OnePageGuts(props: props,links: mdlinks)
        }//let url
        return nil
    }//incorporateParseResults
    
    func scraper( url theURL:URL,  html: String)   -> ParseResults? { 
        if firstTime {
            recordExporter.addHeaderToExportStream()
            firstTime = false
        }
        do {
            assert(html.count != 0 , "No html to parse")
            // try lgfuncs(lgFuncs:lgFuncs,theURL: theURL,html: html,links: &links)
            let scrblock = try lgFuncs.scrapeAndAbsorbFunc(theURL: theURL,html: html )
            return  ParseResults(url: theURL,
                                 status: .succeeded, pagetitle: scrblock.title,
                                 links: scrblock.links,  tags: [])
        }
        catch {
            print("cant parse \(theURL) error is \(error)")
            return  nil
        }
    }
    
}
