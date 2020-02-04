
//  Created by william donner on 4/19/19.
//

import Foundation


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
    }
    
    
    func  incorporateParseResults(pr:ParseResults,imgurl:String="") throws -> OnePageGuts? {
        
        var mdlinks : [Fav] = []  // must reset each time !!
        // move the props into a record
        guard let url = pr.url else { fatalError() }
        
        for link in pr.links {
            if let linkref = link.href { // sometimes no href
            let href =  linkref.absoluteString //yikes
            if !href.hasSuffix("/" ) {
                crawlblock.albumurl = url.absoluteString
                crawlblock.name = link.title
                crawlblock.songurl = href
                crawlblock.cover_art_url = ""
                mdlinks.append(Fav(name:crawlblock.name ?? "??", url:crawlblock.songurl,comment:""))
                recordExporter.addRowToExportStream(cont: crawlblock)
            }
            }
        }
        
        // if we are writing md files for Publish
        if let aurl = crawlblock.albumurl {
            // figure out the coverarturl here, either take the default for the bandsite or take the first one in the mdlinks
            for alink in mdlinks {
                let x =  alink.url.components(separatedBy: ".").last ?? "fail"
                if lgFuncs.isImageExtensionFunc(x) {
                    crawlblock.cover_art_url = alink.url
                    break
                }
            }
            
            if crawlblock.cover_art_url == "" {
                crawlblock.cover_art_url = imgurl
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
