//
//  Igcrawlwidedeep.swift
//  
//
//  Created by william donner on 1/10/20.
//

import Foundation

// nothing public here

final class CrawlTable {
    
    private  var crawlCountPeak: Int = 0
    private  var crawlCount = 0 //    var urlstouched: Int = 0
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
                    }
                }
                catch {
                    print("cant crawl \(error)")
                }
            }
        }
    }
}

////////

final class InnerCrawler : NSObject {
    private(set)  var ct =  CrawlTable()
    private var crawloptions: LoggingLevel
    private  var transformer:Transformer
    private var lgFuncs : LgFuncProts
    private(set) var grubber:ScrapingMachine
    private(set) var places: [RootStart] = [] // set by crawler
    private var first = true
    
    init(roots:[RootStart],
         grubber:ScrapingMachine,
         transformer:Transformer,
         lgFuncs:LgFuncProts,
         logLevel:LoggingLevel = .none) throws {
        self.places = roots
        self.grubber = grubber
        self.crawloptions = logLevel
        self.transformer = transformer
        self.lgFuncs = lgFuncs
    }
}
extension InnerCrawler {
    func bigCrawlLoop(crawlStats:KrawlingInfo, finally:@escaping ReturnsCrawlStats) {
        // the places come in from the config file when it is parsed so add them to the crawl list now
        places.forEach(){ place  in
            guard  let url = URL(string:place.urlstr) else { fatalError() }
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
    
    
    func crawlOne(rootURL:URL, stats:KrawlingInfo ) throws -> OnePageGuts? {
        
        // this is really where the action starts, we crawl from RootStart
        
        // the baseURL for the crawling hierarchy if any, is gleened from RootStart
        
        let topurlstr = URLFromString(rootURL.absoluteString)
        // in this case the brandujrl is the topurl
        guard let parserez =  self.grubber.scrapeFromURL(rootURL)  else {
            print ("load and scrape returned zilch")
            return nil
        }
        // take all these urls and put them on the end of the crawl list as Leafs
        guard let _ = parserez.url else {
            return nil
        }
        
        guard parserez.status == .succeeded else {
            stats.addStatsBadCrawlRoot(urlstr: topurlstr)
            return nil
        }
        guard  parserez.links.count > 0 else {
            stats.addStatsBadCrawlRoot(urlstr: topurlstr)
            return nil
        }
        
        stats.addStatsGoodCrawlRoot(urlstr: topurlstr)
        if self.crawloptions == .verbose  {
            print("\(self.ct.items.count),",terminator:"")//,\u{001B}[;m
            fflush(stdout)
        }
        
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
        return try transformer.incorporateParseResults(pr: parserez)
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
    
    func delay(_ delay:Double, completion:@escaping ()->()){ // thanks Matt
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: completion)
    }
}
