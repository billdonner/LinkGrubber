//
//  outercrawler.swift 
//  
//
//  Created by william donner on 1/19/20.
//

import Foundation

// nothing public here
struct OnePageGuts {
    let props : CustomPageProps
    let links : [Fav]
}

final class OuterCrawler {
    private var returnsCrawlResults : ReturnsGrubberStats
    private var icrawler : InnerCrawler
    private var krawlInfo : KrawlingInfo
    private var transformer:Transformer
    private var pageMakerFunc:  PageMakerFunc //  Audio(bandfacts: bandSiteParams).makeAudioListMarkdown
    

    
    init(roots:[RootStart],transformer:Transformer,
        pageMakerFunc: @escaping PageMakerFunc,
        matcherFunc : @escaping  MatchingFunc,
         loggingLevel:LoggingLevel,
         lgFuncs:LgFuncs ,
         returnsResults:@escaping ReturnsGrubberStats)
        throws {
            self.transformer = transformer
            self.pageMakerFunc = pageMakerFunc
            self.krawlInfo = KrawlingInfo()
            self.returnsCrawlResults = returnsResults
            let lk = ScrapingMachine(scraper: transformer.scraper,matcher:matcherFunc)
            // we start the inner crawler right here
            self.icrawler =  try InnerCrawler(roots:roots,  grubber:lk, transformer: transformer, pagemaker: pageMakerFunc ,logLevel:loggingLevel)
            startMeUp(roots, icrawler: icrawler )
    }

    
    private func startMeUp(_ roots:[RootStart],icrawler:InnerCrawler) {
        let startTime = Date()
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
            
            self.returnsCrawlResults(grubstats)
            
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
    // this could be improved to work asynchronously in the background??
    private func fetchHTMLFromURL( _ url:URL)->(String,String){
        do{
            let htmlstuff = try String(contentsOf: url)
            return (url.absoluteString,htmlstuff )
        }
        catch {
            consoleIO.writeMessage("Cant fetch string contents of \(url)",to: .error)
        }
        return ("","")
    }
    
    // this is the major entry point
    func scrapeFromURL( _ urlget:URL) -> ParseResults? {
        
        guard matchx(urlget) else { return nil }
        
        let  (  _, html) = fetchHTMLFromURL(urlget)
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
                                 status: .succeeded, pagetitle:parseResultz!.pagetitle, links:parseResults.links,  props: parseResults.props,  tags: [])
               
            default: return nil
            
            }
        }
    }
}


