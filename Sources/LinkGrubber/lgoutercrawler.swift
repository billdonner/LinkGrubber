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
         loggingLevel:LoggingLevel,
         lgFuncs:LgFuncs ,
         returnsResults:@escaping ReturnsGrubberStats)
        throws {
            self.transformer = transformer
         self.pageMakerFunc = pageMakerFunc
            self.krawlInfo = KrawlingInfo()
            self.returnsCrawlResults = returnsResults
            let lk = ScrapingMachine(scraper: transformer.scraper)
            // we start the inner crawler right here
            self.icrawler =  try InnerCrawler(roots:roots,  grubber:lk, transformer: transformer, pagemaker: pageMakerFunc ,logLevel:loggingLevel)
            startMeUp(roots, icrawler: icrawler )
    }
    
    
    
//    func exportone(pr:ParseResults)->() {
//        //each page we hit gets scraped and incorporated
//        do {
//            let (props,links) = try transformer.incorporateParseResults(pr: pr)
//            
//        }
//        catch {
//            print("couldnt scrape onpageworth \(error)")
//        }
//    }
    
    
    private func startMeUp(_ roots:[RootStart],icrawler:InnerCrawler) {
        let startTime = Date()
        // let baseurltag = (icrawler.baseURL != nil) ?  icrawler.baseURL!.absoluteString : "baseurl fail" //XXXXXXXX
        print("[crawler] starting \(startTime), root \(roots[0].urlstr) please be patient")
        
        icrawler.bigCrawlLoop( crawlStats: krawlInfo) {
            _ in
            // finally finished !
            
            let (count,peak) = self.icrawler.crawlingStats()
            let crawltime = Date().timeIntervalSince(startTime)
            
            self.finalSummary(stats: self.krawlInfo,
                              count:count,
                              peak:peak,
                              crawltime:crawltime)
            
            let crawlResults = LinkGrubberStats(added:count,peak:peak,elapsedSecs:crawltime,secsPerCycle:crawltime/Double(count), count1: self.krawlInfo.goodurls.count, count2:self.krawlInfo.badurls.count, status:200)
            /// this is where we will finally wind up, need to call the user routine that was i
            
            self.returnsCrawlResults(crawlResults)
            
        }
    }
    
    private   func finalSummary (stats:KrawlingInfo, count:Int,peak:Int,crawltime:TimeInterval) {
        // copy into  TestResultsBlock
        var fb = TestResultsBlock()
        fb.reportTitle = "Crawl Summary"
        // this is not always good
        fb.command = CommandLine.arguments
        fb.rootcrawlpoints = stats.goodurls.map() {  LinkGrubber.kleenURLString($0)!.string }
        fb.leafpoints = stats.badurls.map() {  LinkGrubber.kleenURLString($0)!.string }
        fb.status = stats.badurls.count > 0 && stats.goodurls.count > 0 ? 201:(stats.goodurls.count > 0 ? 200:202)
        //let elapsed = String(format:"%02.3f ",crawltime)
        let percycle = count <= 0 ? 0.0 : (crawltime / Double(count))
        
        
        let statsblock = LinkGrubberStats(added:count,peak:peak,elapsedSecs:crawltime,secsPerCycle:percycle,
                                           count1: self.krawlInfo.goodurls.count, count2:self.krawlInfo.badurls.count,
                                           status:200)
        
        fb .crawlStats = statsblock
        
        //emitResultsAsTrace(fb)//), trace)
    }
}

 
final class ScrapingMachine:NSObject {
    private var scraperx:PageScraperFunc
    init(scraper:@escaping PageScraperFunc) {
        self.scraperx = scraper
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
    func scrapeFromURL( _ urlget:URL,
                        parsingTechnique:ParseTechnique) -> ParseResults? {
        
        let  (  _, html) = fetchHTMLFromURL(urlget)
        do {
            // [3] if no incoming, just get out of here
            if html.count == 0 {
              return nil
            }
            // [4] parse the incoming and stash the results, regardless
            // note = html must already be filled in and hence urget is for info
            let  parseResultz  =  scraperx(parsingTechnique,urlget,   html)
            
            guard let parseResults = parseResultz else {
                return nil
                
            }
            // [5] figure out what to do
            let status:ParseStatus = parseResults.status
            switch status {
            case .succeeded: 
                   return ParseResults(url:urlget,
                                 technique: parsingTechnique,
                                 status: .succeeded, pagetitle:parseResultz!.pagetitle, links:parseResults.links,  props: parseResults.props,  tags: [])
               
            default: return nil
            
            }
        }
    }
}


