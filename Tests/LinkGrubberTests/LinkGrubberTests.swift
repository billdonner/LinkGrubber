import XCTest
@testable import LinkGrubber

final class LinkGrubberTests: XCTestCase {
    
 
//        var artist : String = ""
//        var venueShort : String  = ""
//        var venueLong : String  = ""
//        var coverArtURL : String  = ""
//        var crawlTags:[String] = []
       class TestParams: FileSiteProt {
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
                .grub(roots:[RootStart(name:"1/2 dead", urlstr:"https://billdonner.com/linkgrubber/empty-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
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
    

    
    func testGrubber0() {
        let pmf:PageMakerFuncSignature = {a,b,c,d,e in
            print(a,b,e.count)
        }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"1/2 dead", urlstr:"https://billdonner.com/linkgrubber/zero-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
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
    
    func testGrubber1() {
        let pmf:PageMakerFuncSignature = {a,b,c,d,e in
            print(a,b,e.count)
        }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"1/2 dead", urlstr:"https://billdonner.com/linkgrubber/one-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
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
    func testGrubber2() {
        let pmf:PageMakerFuncSignature = {a,b,c,d,e in
            print(a,b,e.count)
        }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"1/2 dead", urlstr:"https://billdonner.com/linkgrubber/two-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
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
    ("testGrubber", testGrubber),
    ("testGrubber0", testGrubber0),
    ("testGrubber1", testGrubber1),
    ("testGrubber2", testGrubber2)
    ]
}
