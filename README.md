# LinkGrubber
0.1.21


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


```swift 
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
    
```


