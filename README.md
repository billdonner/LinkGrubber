# LinkGrubber
0.1.35 changed several lets to vars and moved to outer level to increase lifetimes


<p align="center">
<img src="https://billdonner.com/images/fists/fistUp1024x1024.png" width="200" max-width="90%" alt="Publish" />
</p>




## Crawl Your Remote Assets

In my case, these are MP3 files from band performances over the years. 

There are a few sites here that you can crawl:  https://billdonner.github.io/LinkGrubber

## Generate CSV an JSON for Data Analysis

LinkGrubber writes a file for Excel or Numbers analsysis of your assets, and a json version for your own programs.

## Callback to Your Own File Maker

Typically, as pages of links are grubber you'll want to write a file. It's up to you.

My Static Websites, built on Publish from John Sundell, generates MarkDown Files

#### first declare some functions needed by the grubber

```swift 
private struct LgFuncs: LgFuncProts {
    
    func scrapeAndAbsorbFunc ( theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock {
        try HTMLExtractor.generalScrapeAndAbsorb ( theURL:theURL, html:html )
    }
    func pageMakerFunc(_ props:CustomPageProps,  _ links: [Fav] ) throws -> () {
        // print ("MAKING PAGE with props \(props) linkscount: \(links)")
    }
    func matchingFunc(_ u: URL) -> Bool {
        return  u.absoluteString.hasPrefix("https://billdonner.")
    }
    func isImageExtensionFunc (_ s:String) -> Bool {
        ["jpg","jpeg","png"].includes(s)
    }

}
```
#### then make a LinkGrubber and Grub

  ```swift 
        do {
                  let _ = try LinkGrubber()
                      .grub(roots:[rootstart],
                            opath:"/x/y/z",
                            logLevel: .verbose,
                            lgFuncs: lgFuncs)
                      { crawlerstats in
                          self.grubstats = crawlerstats
                  }
              }
              catch {
                  print("couldnt grub \(error)")
              }
    
```
#### now use  .csv file in Numbers or Excel

There's a csv file for you at the end of the day

### use .json file for further development endevors


