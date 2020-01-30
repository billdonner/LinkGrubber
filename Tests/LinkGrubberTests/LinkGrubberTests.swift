import XCTest
@testable import LinkGrubber
import Kanna

// these functions must be supplied by the caller of LinkGrubber.grub()
func scraperReturnsNothing (_  lgFuncs:LgFuncs,url: URL, s: String ) throws -> ScrapeAndAbsorbBlock {
    print("[LinkGrubber] scraping \(url)")
    return ScrapeAndAbsorbBlock(title: "scraperReturnsNothing",links: [])
}

// for testing only , we'll use kanna

func kannaScrapeAndAbsorb (lgFuncs:LgFuncs,theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock {
    func absorbLink(href:String? , txt:String? ,relativeTo: URL?, tag: String, links: inout [LinkElement]) {
        if let lk = href, //link["href"] ,
            let url = URL(string:lk,relativeTo:relativeTo) ,
            let linktype = processExtension(lgFuncs: lgFuncs, url:url, relativeTo: relativeTo) {
            
            // strip exension if any off the title
            let parts = (txt ?? "fail").components(separatedBy: ".")
            if let ext  = parts.last,  let front = parts.first , ext.count > 0
            {
                let subparts = front.components(separatedBy: "-")
                if let titl = subparts.last {
                    let titw =  titl.trimmingCharacters(in: .whitespacesAndNewlines)
                    links.append(LinkElement(title:titw,href:url.absoluteString,linktype:linktype, relativeTo: relativeTo))
                }
            } else {
                // this is what happens upstream
                if  let txt  = txt  {
                    links.append(LinkElement(title:txt,href:url.absoluteString,linktype:linktype, relativeTo: relativeTo))
                }
            }
        }
    }// end of absorbLink
    let doc = try  Kanna.HTML(html: html, encoding: .utf8)
    let title = doc.title ?? "<untitled>"
    var absorbedlinks:[LinkElement] = []
    for link in doc.xpath("//a") {
        absorbLink(href:link["href"],
                   txt:link.text,
                   relativeTo:theURL,
                   tag: "media",links:&absorbedlinks )
    }
    return ScrapeAndAbsorbBlock(title:  title, links:absorbedlinks)
}

struct LgFuncs: LgFuncProts {
    
    func scrapeAndAbsorbFunc ( theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock {
        try kannaScrapeAndAbsorb ( lgFuncs: self,theURL:theURL, html:html )
    }
    func pageMakerFunc(_ props:CustomPageProps,  _ links: [Fav] ) throws -> () {
       // print ("MAKING PAGE with props \(props) linkscount: \(links)")
    }
    func matchingFunc(_ u: URL) -> Bool {
        return  true//u.absoluteString.hasPrefix("https://billdonner.github.io/LinkGrubber/")
    }
    func isImageExtensionFunc (_ s:String) -> Bool {
        ["jpg","jpeg","png"].includes(s)
    }
    private   func isAudioExtensionFunc(_ s:String) -> Bool {
        ["mp3","mpeg","wav"].includes(s)
    }
    private    func isMarkdownExtensionFunc(_ s:String) -> Bool{
        ["md", "markdown", "txt", "text"].includes(s)
    }
    
    func isNoteworthyExtensionFunc(_ s: String) -> Bool {
        isImageExtensionFunc(s) || isMarkdownExtensionFunc(s)
    }
    func isInterestingExtensionFunc (_ s:String) -> Bool {
        isImageExtensionFunc(s) || isAudioExtensionFunc(s)
    }
}

//////////////////////// Test Cases //////////////////////////

class LinkGrubberTests: XCTestCase {
    
    var opath:String!
    var grubstats : LinkGrubberStats? = nil
    let lgFuncs = LgFuncs()
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
                      logLevel: LoggingLevel.verbose,
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
                    expecting: expectedResults(93,0,0)) // will deliberately fail
    }

    func testGrubberHd2019() {
        runGrubber (RootStart(name:"testGrubberHd2019",
                              url:URL(string:"https://billdonner.com/halfdead/2019/")!),
                    expecting: expectedResults(38,0,0))
    }
    func testGrubber0() {
        runGrubber (RootStart(name:"zero-site",
                              url:URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/zero-site/")!),
                    expecting:  expectedResults(2,1,1))
    }
    func testGrubber1() {
        runGrubber(RootStart(name:"one-site",
                             url:URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/one-site/")!),
                   expecting: expectedResults(3,1,2))
    }
    func testGrubber2() {
        runGrubber(RootStart(name:"two-site",
                             url:URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/two-site/")!),
                   expecting: expectedResults(3,1,2))
    }
    static var allTests = [
        ("testGrubber0", testGrubber0),
        ("testGrubber1", testGrubber1),
        ("testGrubber2", testGrubber2),
        ("testGrubberHd2019", testGrubberHd2019),
        ("testGrubberHdFull", testGrubberHdFull)
    ]
}
