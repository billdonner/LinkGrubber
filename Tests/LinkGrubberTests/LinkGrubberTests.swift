import XCTest
@testable import LinkGrubber

final class LinkGrubberTests: XCTestCase {
    
    class TestParams: BandSiteProt & FileSiteProt {
        var artist : String = ""
        var venueShort : String  = ""
        var venueLong : String  = ""
        var coverArtURL : String  = ""
        var crawlTags:[String] = []
        
        var pathToContentDir : String  = ""
        var pathToResourcesDir: String  = ""
        var pathToOutputDir: String  = ""
        var matchingURLPrefix : String = ""
        var specialFolderPaths: [String] = []
    }
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LinkGrubberHello().text, "Hello, World!")
    }
    func testGrubber() {
        let pmf:PageMakerFuncSignature = {a,b,c,d,e in
            print(a,b,e.count)
        }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"1/2 head", urlstr:"https://billdonner.com/halfdead")],
                      opath:"/Users/williamdonner/localscratch",
                      params: testparams,
                      logLevel:.none)
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    
    
    
// test params


static var allTests = [
    ("testExample", testExample),
    ("testGrubber", testGrubber),
]
}
