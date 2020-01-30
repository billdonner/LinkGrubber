import XCTest
@testable import LinkGrubber

final class LinkGrubberTests: XCTestCase {
    
    class TestParams: FileSiteProt {
        var logLevel: LoggingLevel = .none
        var lgFuncs: LgFuncs = defaults()
        var pathToOutputDir: String  = ""
        var matchingURLPrefix : String = "https://billdonner.github.io/LinkGrubber"
    }
    
    // test params
    static func testscraperfunc  (_  lgFuncs:LgFuncs,url: URL, s: String ) throws -> ScrapeAndAbsorbBlock {
        print("[LinkGrubber] scraping \(url)")
        return ScrapeAndAbsorbBlock(title: "linkgrubber.defaults()",links: [])
    }
    
    static func defaults() -> LgFuncs {
        return LgFuncs(imageExtensions: ["jpg","jpeg","png"],
                       audioExtensions: ["mp3","mpeg","wav"],
                       markdownExtensions: ["md", "markdown", "txt", "text"],
                       scrapeAndAbsorbFunc: testscraperfunc)
    }
    
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LinkGrubberHello().text, "Hello, World!")
    }
    
    var matchf:MatchingFunc!
    var pmf:PageMakerFunc!
    var testparams: TestParams!
    
    override func setUp() {
        func matchingfunc (theURL:URL) -> Bool {
            return  theURL.absoluteString.hasPrefix("https://billdonner.github.io/LinkGrubber/")
        }
        
        matchf = matchingfunc
        pmf  = {props,favs in
            print(props," ",favs.count)
        }
        testparams = TestParams()
    }
    func testGrubber() {
        
        do {
            let _ = try LinkGrubber()
                .grub(roots:[RootStart(name:"empty-site",
                                       urlstr:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/empty-site/")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams, pageMakerFunc:  pmf, matchingFunc: matchf)
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    
    
    
    func testGrubber0() {
        
        do {
            let _ = try LinkGrubber()
                .grub(roots:[RootStart(name:"zero-site",
                                       urlstr:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/zero-site/")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,  pageMakerFunc: pmf, matchingFunc: matchf )
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    
    func testGrubber1() {
        
        do {
            let _ = try LinkGrubber()
                .grub(roots:[RootStart(name:"one-site",
                                       urlstr:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/one-site/")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,  pageMakerFunc: pmf, matchingFunc: matchf )
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    func testGrubber2() {
        
        do {
            let _ = try LinkGrubber()
                .grub(roots:[RootStart(name:"two-site",
                                       urlstr:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/two-site/")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,
                      pageMakerFunc: pmf, matchingFunc: matchf   )
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    
    
    static var allTests = [
        ("testGrubber", testGrubber),
        ("testGrubber0", testGrubber0),
        ("testGrubber1", testGrubber1),
        ("testGrubber2", testGrubber2)
    ]
}
