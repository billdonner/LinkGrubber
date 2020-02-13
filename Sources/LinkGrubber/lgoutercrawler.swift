//
//  outercrawler.swift 
//  
//
//  Created by william donner on 1/19/20.
//

import Foundation

// nothing public here

final class OuterCrawler { 
    private var icrawler : InnerCrawler!
    private var krawlInfo : KrawlingInfo
    private var transformer:Transformer
    private var lgFuncs:LgFuncProts
    
    init(transformer:Transformer,
         lgFuncs:LgFuncProts)  {
            self.transformer = transformer
            self.lgFuncs = lgFuncs
            self.krawlInfo = KrawlingInfo()
            // we dont start the inner crawler right here
         
    }
    
    func startMeUp(_ roots:[RootStart], loggingLevel:LoggingLevel ,
            returnsResults:@escaping ReturnsGrubberStats) throws {
        let startTime = Date()

        let lk = ScrapingMachine(scraper: transformer.scraper,matcher:lgFuncs.matchingFunc )
        self.icrawler =  try InnerCrawler(roots:roots,  grubber:lk, transformer: transformer, lgFuncs: lgFuncs ,logLevel:loggingLevel)
                
        icrawler.bigCrawlLoop( crawlStats: krawlInfo) {
            _ in
            // finally finished !
            
            let (count,peak) = self.icrawler.crawlingStats()
            let crawltime = Date().timeIntervalSince(startTime)
            let percycle =  count == 0  ? 0 : crawltime/Double(count)
            let grubstats = LinkGrubberStats(added:count,
                                             peak:peak,
                                             elapsedSecs: crawltime,
                                             secsPerCycle: percycle,
                                             count1: self.krawlInfo.goodurls.count,
                                             count2:self.krawlInfo.badurls.count,
                                             status:200)
            /// this is where we will finally wind up, need to call the user routine that was i
            
             returnsResults(grubstats)
            
        }
    }
}


final class ScrapingMachine:NSObject {
    private var scraperx:PageScraperFunc
    private var matchx:MatchingFunc
    
    init(scraper:@escaping PageScraperFunc, matcher:@escaping MatchingFunc) {
        self.scraperx = scraper
        self.matchx = matcher
        super.init()
    }
    // this could be improved to work even more asynchronously
    // but we are already running in the background
    
    
      //MARK:- asynchronous call
    private func fetchHTMLFromURLviaDownloadTask( _ url:URL,
                                                   finally:@escaping ((String?)->())) {
            let task =  URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
                if let localURL = localURL {
                    do {
                     let string = try String(contentsOf: localURL)
                        finally(string)
                   
                    }
                        catch {
                            consoleIO.writeMessage("*********Cant fetch string contents  \(error)",to: .error)
                            finally(nil)
                        }
                }
            }
            
            task.resume()
      
        }
    //MARK: - synchronous call
      func fetchHTMLFromURL ( _ url:URL )->String?{
        let semaphore = DispatchSemaphore(value:0)
        let q = DispatchQueue.global()

        var resultstring:String?
        q.async { [weak self] in
            guard let self = self else {return}
            
            // start here
            self.fetchHTMLFromURLviaDownloadTask(url) { s in
                resultstring = s
                semaphore.signal()
            }
   
        }
        // 5 sec timeout
        let  _ = semaphore.wait(timeout: .now() + 5)
        return resultstring
 
    }
    // this is the major entry point
    func scrapeFromURL( _ urlget:URL) -> ParseResults? {
        
        guard matchx(urlget) else { return nil }
        
        let   html  = fetchHTMLFromURL(urlget) // synchronous call
        if let html = html {
            do {
                // [3] if no incoming, just get out of here
                if html.count == 0 {
                    return nil
                }
                // [4] parse the incoming and stash the results, regardless
                // note = html must already be filled in and hence urget is for info
                let  parseResultz  =  scraperx( urlget,   html)
                
                guard let parseResults = parseResultz else {
                    return nil
                    
                }
                // [5] figure out what to do
                let status:ParseStatus = parseResults.status
                switch status {
                case .succeeded:
                    return ParseResults(url:urlget,
                                        status: .succeeded, pagetitle:parseResultz!.pagetitle, links:parseResults.links, tags: [])
                default: return nil
                    
                }
            }
        }
        return nil
    }
}


