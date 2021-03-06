//
//  Igcrawlwidedeep.swift
//  
//
//  Created by william donner on 1/10/20.
//

import Foundation

// nothing public here

var allsmallmo:[SmallMo] = []

final class CrawlTable {
    
    private  var crawlCountPeak: Int = 0
    private  var crawlCount = 0
    private  var crawlState :  CrawlState = .crawling
    
    //
    // urls serviced from the top of this list
    // urls are added to the bottom
    //
    private(set)  var  items:[URL] = []
    private var touched:Set<String> = [] // optimization to see if item on either list
    
    func crawlStats() -> (Int,Int) {
        return (crawlCount,crawlCountPeak)
    }
    func addToListUnquely(_ url:URL) {
        let urlstr = url.absoluteString
        if !touched.contains(urlstr){
            
            items.append(url)
            touched.insert( urlstr)
            crawlCount += 1
            let now = items.count
            if now > crawlCountPeak { crawlCountPeak = now }
            //// print("----added \(crawlCount) -  \(urlstr) to crawllist \(now) \(crawlCountPeak)")
            
        }
    }
    
    func popFromTop() -> URL?{
        if items.count == 0 {return nil}
        let topurl =  items.removeFirst() // get next to process
        return topurl
    }
    
    func convertOpgToSmallMo(opg:OnePageGuts) -> SmallMo? {
        var anchors:[AnchorInfo] = []
        for (idx,link) in opg.links.enumerated() {
            anchors.append(AnchorInfo(t:link.name,l:link.url,o:idx+1))
        }
        if anchors.count == 0  { return  nil }
        // note we are using urlstr, not title, which just has the title of last song
        let m = SmallMo(title:opg.props.urlstr,refs: anchors)
        return m
    }
    fileprivate func crawlLoop (finally:  ReturnsCrawlStats,  stats: KrawlingInfo, innerCrawler:InnerCrawler,   lgFuncs:LgFuncProts) {
        while crawlState == .crawling {
            if items.count == 0 {
                crawlState = .done
                
                innerCrawler.crawlDone( stats,finally)
                return // ends here
            }
            // get next to process
            guard  let newStart = popFromTop() else {
                return
            }
            // squeeze down before crawling to keep memory reasonable
            autoreleasepool {
                do{
                    let opg =  try innerCrawler.crawlOne(rootURL: newStart ,stats:stats )
                    // now publish the guts
                    if let opg = opg {
                        try lgFuncs.pageMakerFunc(opg.props,opg.links)
                        if  let smallmo = convertOpgToSmallMo(opg: opg) {
                        allsmallmo.append(smallmo)
                        }
                    }
                }
                catch {
                    fatalError("cant crawl \(error)")
                }
            }
        }
    }
}

////////

final class InnerCrawler : NSObject {
    private(set)  var ct =  CrawlTable()
    private var logLevel: LoggingLevel
    private  var transformer:Transformer
    private var lgFuncs : LgFuncProts
    private(set) var grubber:ScrapingMachine
    private(set) var places: [RootStart] = [] // set by crawler
    private var first = true
    
    init(roots:[RootStart],
         grubber:ScrapingMachine,
         transformer:Transformer,
         lgFuncs:LgFuncProts,
         logLevel:LoggingLevel) throws {
        self.places = roots
        self.grubber = grubber
        self.logLevel = logLevel
        self.transformer = transformer
        self.lgFuncs = lgFuncs
    }
}
extension InnerCrawler {
    func bigCrawlLoop(crawlStats:KrawlingInfo, finally:@escaping ReturnsCrawlStats) {
        // the places come in from the config file when it is parsed so add them to the crawl list now
        places.forEach(){ place  in
            guard  let url = URL(string:place.urlstr) else { fatalError() }
            print("[LinkGrubber] scanning \(url)")
            addToCrawlList(url)
        }
        ct.crawlLoop(finally: finally,stats: crawlStats, innerCrawler: self,   lgFuncs:lgFuncs)
    }
    
    func crawlingStats()->(Int,Int) {
        return ct.crawlStats()
    }
    
    func addToCrawlList(_ f:URL ) {
        ct.addToListUnquely(f)
    }
    func crawlDone( _ crawlerContext: KrawlingInfo,  _ finally: ReturnsCrawlStats) {
        // here we should output the very last trailer record
        //        print("calling whendone from crawldone from crawlingcore with crawlcontext \(crawlerContext)  ")
        finally( crawlerContext)// everything alreadt passed
    }
    fileprivate func logprint(_ pre:String) {
        print(pre,terminator:"")
        fflush(stdout)
    }
    fileprivate func logpre(_ pre:String) {
        if self.logLevel == .verbose  {
            logprint(pre)
        }
    }
    
    
    fileprivate func emitBadness(_ stats: KrawlingInfo, _ topurlstr: URLFromString, pre:String) -> OnePageGuts? {
        stats.addStatsBadCrawlRoot(urlstr: topurlstr)
        logpre(pre)
        return nil
    }
    
    func crawlOne(rootURL:URL, stats:KrawlingInfo ) throws -> OnePageGuts? {
        
        // this is really where the action starts, we crawl from RootStart
        
        // the baseURL for the crawling hierarchy if any, is gleened from RootStart
        
        let topurlstr = URLFromString(rootURL.absoluteString)
        // in this case the brandujrl is the topurl
        guard let parserez =  self.grubber.scrapeFromURL(rootURL)  else {
            return emitBadness(stats, topurlstr,pre: "[LinkGrubber] noscrape:⛑  \(topurlstr.string)")
        }
        // take all these urls and put them on the end of the crawl list as Leafs
        guard  (parserez.url != nil) && parserez.status == .succeeded else {
            return emitBadness(stats, topurlstr,pre: "[LinkGrubber] parsefail:⛑ \(topurlstr.string) ")
        }
        
        guard parserez.links.count > 0 else {
            return emitBadness(stats, topurlstr,pre: "[LinkGrubber] nolinks:⛑  \(topurlstr.string) ")
        }
        
        first = false
        parserez.links.forEach(){ linkElement in
            switch linkElement.linktype {
            case .hyperlink:
                if  let z = linkElement.href,
                    z.pathExtension == "" {
                    self.addToCrawlList(z)
                }
            case .leaf:
                break
            }
        }//roots for each
        
        
        let guts = try transformer.incorporateParseResults(pr: parserez)
        guard let opg = guts else  {
            return emitBadness(stats, topurlstr,pre: "[LinkGrubber] noinc:⛑  \(topurlstr.string) ")
        }
        // now lets turn opg into a smallmo and append to performances
        
    
        // if we've gotten this far it is good
        stats.addStatsGoodCrawlRoot(urlstr: topurlstr)
        if LoggingLevel.verbose == logLevel {
            logprint( "[LinkGrubber] added: \(topurlstr.string) links:\(opg.links.count) tags:\(opg.props.tags.count)")
        } else {
            let pre = first ? "[LinkGrubber] tracing: ":","
            logprint("\(pre)\(opg.links.count)")
        }
        return opg
    }
}



private func outString (_ s:String) {
    print(s)
}

func trace(_ cat:String,msg:String?=nil,quotes:Bool=true,last:Bool=false) {
    guard let mess = msg else { outString(cat); return }
    let comma = last ? "" : ","
    switch quotes {
    case true:
        let t = """
        "\(cat)":"\(mess)"\(comma)
        """
        outString (t)
    case false:
        let t = """
        "\(cat)":\(mess)\(comma)
        """
        outString (t)
    }
}
