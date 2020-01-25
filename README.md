# LinkGrubber
0.1.6
 
<p align="center">
<img src="https://billdonner.com/images/fists/fistUp1024x1024.png" width="300" max-width="90%" alt="Publish" />
</p>

## Crawl Your Remote Music Assets

## Generate CSV an JSON for Data Analysis

## Generate MarkDown Files for Publish


```swift 

  class TestParams: FileSiteProt {
    var pathToContentDir : String  = ""
    var pathToResourcesDir: String  = ""
    var pathToOutputDir: String  = ""
    var matchingURLPrefix : String = ""
    var specialFolderPaths: [String] = []
}


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
```


