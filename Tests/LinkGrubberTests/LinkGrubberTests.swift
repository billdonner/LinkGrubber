import XCTest
@testable import LinkGrubber
import HTMLExtractor
//import Kanna

let LOGGINGLEVEL = LoggingLevel.none


// these functions must be supplied by the caller of LinkGrubber.grub()
 //////////////////////// Test Cases //////////////////////////

final class LinkGrubberTests: XCTestCase {
     

private struct LgFuncs: LgFuncProts {
    
    func scrapeAndAbsorbFunc ( theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock {
        try HTMLExtractor.generalScrapeAndAbsorb ( theURL:theURL, html:html )
    }
    func pageMakerFunc(_ props:CustomPageProps,  _ links: [Fav] ) throws -> () {
       // print ("\nMAKING PAGE with props \(props) linkscount: \(links.count)")
    }
    func matchingFunc(_ u: URL) -> Bool {
        return  u.absoluteString.hasPrefix("https://billdonner.")
    }
    func isImageExtensionFunc (_ s:String) -> Bool {
        ["jpg","jpeg","png"].includes(s)
    }

}


    var opath:String!
    var grubstats : LinkGrubberStats? = nil
    private let lgFuncs = LgFuncs()
    var anticipatedstats : LinkGrubberStats? = nil
    
    override func setUp() {
        grubstats = nil
        opath = "/Users/williamdonner/LocalScratch/aabonus"
    }
    
    // when finally done, check the crawler stats
    override func tearDown() {
        while grubstats == nil {
            sleep(1)
        }
        XCTAssertTrue(self.grubstats == self.anticipatedstats, " does not match anticipated results ************************")
    }
    
    func runGrubber(_ rootstart:RootStart,expecting:LinkGrubberStats) {
        self.anticipatedstats = expecting
        do {
            let _ = try LinkGrubber()
                .grub(roots:[rootstart],
                      opath:opath,
                      logLevel: LOGGINGLEVEL,
                      lgFuncs: lgFuncs)
                { crawlerstats in
                    self.grubstats = crawlerstats
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    
    
    private func expectedResults (_ x:Int,_ y:Int,_ z:Int) -> LinkGrubberStats {
        LinkGrubberStats(added: x , peak: x , elapsedSecs: 0, secsPerCycle: 0, count1: y, count2: z, status: 200)
    }
    func testGrubberHdFull() {
        runGrubber (RootStart(name:"testGrubberHdFull",
                              url:URL(string:"https://billdonner.com/halfdead/")!),
                    expecting: expectedResults(97,96,1)) // will deliberately fail
    }
    
    func testGrubberHd2019() {
        runGrubber (RootStart(name:"testGrubberHd2019",
                              url:URL(string:"https://billdonner.com/halfdead/2019/")!),
                    expecting: expectedResults(38,0,0))
    }
    func testGrubber0() {
        runGrubber (RootStart(name:"zero-site",
                              url:URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/zero-site/")!),
                    expecting:  expectedResults(6,3,3))
    }
    func testGrubber1() {
        runGrubber(RootStart(name:"one-site",
                             url:URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/one-site/")!),
                   expecting: expectedResults(8,4,4))
    }
    func testGrubber2() {
        runGrubber(RootStart(name:"two-site",
                             url:URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/two-site/")!),
                   expecting: expectedResults(1,0,1))
    }
    
    
    static var allTests = [
        ("testGrubber0", testGrubber0),
        ("testGrubber1", testGrubber1),
        ("testGrubber2", testGrubber2),
                     ("testGrubberHd2019", testGrubberHd2019),
                    ("testGrubberHdFull", testGrubberHdFull)
    ]
}
