import XCTest
@testable import LinkGrubber

final class LinkGrubberTests: XCTestCase {
       class TestParams: FileSiteProt {
        var pathToContentDir : String  = ""
        var pathToResourcesDir: String  = ""
        var pathToOutputDir: String  = ""
        var matchingURLPrefix : String = ""
        var specialFolderPaths: [String] = []
    }
    
    // test params
       func testscraperfunc  (_  lgFuncs:LgFuncs,url: URL, title: String , links:inout [LinkElement]) throws -> String {
           print("linkgrubber.defaults",url,title)
           return "linkgrubber.defaults()"
       }

    func defaults() -> LgFuncs {
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
    func testGrubber() {
        let pmf:PageMakerFunc = {props,favs in
            print(props," ",favs.count)
        }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"linkgrubber",
                                       urlstr:"https://billdonner.com/linkgrubber/empty-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,
                      logLevel:.none, lgFuncs:  defaults())
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    

    
    func testGrubber0() {
       let pmf:PageMakerFunc = {props,favs in
                  print(props," ",favs.count)
              }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"linkgrubber", urlstr:"https://billdonner.com/linkgrubber/zero-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,
                      logLevel:.none, lgFuncs:  defaults())
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    
    func testGrubber1() {
      let pmf:PageMakerFunc = {props,favs in
                  print(props," ",favs.count)
              }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"linkgrubber", urlstr:"https://billdonner.com/linkgrubber/one-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,
                      logLevel:.none, lgFuncs:defaults())
                { crawlerstats in
                    print("\(crawlerstats.count1) pages")
            }
        }
        catch {
            print("couldnt grub \(error)")
        }
    }
    func testGrubber2() {
      let pmf:PageMakerFunc = {props,favs in
                  print(props," ",favs.count)
              }
        let testparams = TestParams()
        do {
            let _ = try LinkGrubber(pageMakerFunc: pmf)
                .grub(roots:[RootStart(name:"linkgrubber", urlstr:"https://billdonner.com/linkgrubber/two-site")],
                      opath:"/Users/williamdonner/LocalScratch/aabonus",
                      params: testparams,
                      logLevel:.none, lgFuncs:  defaults())
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
