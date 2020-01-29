# LinkGrubber
0.1.16


<p align="center">
<img src="https://billdonner.com/images/fists/fistUp1024x1024.png" width="200" max-width="90%" alt="Publish" />
</p>




## Crawl Your Remote Assets

In my case, these are MP3 files from band performances over the years. 

[test cases]("https://billdonner.github.io/LinkGrubber")

## Generate CSV an JSON for Data Analysis

LinkGrubber writes a file for Excel or Numbers analsysis of your assets, and a json version for your own programs.

## Callback to Your Own File Maker

Typically, as pages of links are grubber you'll want to write a file. It's up to you.

My Static Websites, built on Publish from John Sundell, generates MarkDown Files


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


