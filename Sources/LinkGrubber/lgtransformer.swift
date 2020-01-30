
//  Created by william donner on 4/19/19.
//

import Foundation

public class Fav {
    public let name: String
    public let url: String
    public  let comment: String
    public init (name:String = "",url:String = "",comment:String = "") {
        self.name = name
        self.url = url
        self.comment = comment
    }
}
extension Array where Element == String  {
    func includes(_ f:Element)->Bool {
        self.firstIndex(of: f) != nil
        }
    }
public struct ScrapeAndAbsorbBlock {
    let title: String
    let links:[LinkElement]
}
public typealias ScrapeAndAbsorbFunc = ( LgFuncs, URL,String ) throws -> ScrapeAndAbsorbBlock


open class LgFuncs {
    public func isImageExtension (_ s:String) -> Bool {
        imageExtensions.includes(s)
    }
    public   func isAudioExtension (_ s:String) -> Bool {
       audioExtensions.includes(s)
    }
    public    func isMarkdownExtension(_ s:String) -> Bool{
        markdownExtensions.includes(s)
    }
    
   private var imageExtensions:[String]
   private var audioExtensions:[String]
   private var markdownExtensions:[String]
   private(set) var scrapeRestore:ScrapeAndAbsorbFunc
    
   public init(imageExtensions:[String],
               audioExtensions:[String],
               markdownExtensions:[String],
               scrapeAndAbsorbFunc:@escaping ScrapeAndAbsorbFunc) {
        self.imageExtensions = imageExtensions
        self.audioExtensions = audioExtensions
        self.markdownExtensions = markdownExtensions
        self.scrapeRestore = scrapeAndAbsorbFunc
    }

   public  func processExtension(url:URL,relativeTo:URL?)->Linktype?{
        let pext = url.pathExtension.lowercased()
        let hasextension = pext.count > 0
        let linktype:Linktype = hasextension == false ? .hyperlink:.leaf
        guard url.absoluteString.hasPrefix(relativeTo!.absoluteString) else {
            return nil
        }
        
        if hasextension {
            guard self.isImageExtension(pext) || self.isAudioExtension(pext) else {
                return nil
            }
            if self.isImageExtension(pext) || self.isMarkdownExtension(pext) {
                print("Processing \(pext) file from \(url)")
            }
        } else
        {
            //  print("no ext: ", url)
        }
        return linktype
    }
}




final class Transformer:NSObject {
    var lgFuncs:LgFuncs
    var recordExporter : RecordExporter!
    private var crawlblock = CrawlBlock()
    var firstTime = true
    var fsProt: FileSiteProt
    

    required  init( recordExporter:RecordExporter,  fsProt: FileSiteProt , lgFuncs:LgFuncs) {
        self.fsProt  = fsProt
        self.lgFuncs = lgFuncs
        self.recordExporter = recordExporter
        super.init()
    }
    deinit  {
        recordExporter.addTrailerToExportStream()
       // print("[crawler] finalized csv and json streams")
    }
    
    
    func  incorporateParseResults(pr:ParseResults,pageMakerFunc:PageMakerFunc,imgurl:String="") throws -> OnePageGuts? {
        var mdlinks : [Fav] = []  // must reset each time !!
        // move the props into a record
        guard let url = pr.url else { fatalError() }
        
        for link in pr.links {
            let href =  link.href!.absoluteString
            if !href.hasSuffix("/" ) {
                crawlblock.albumurl = url.absoluteString
                crawlblock.name = link.title
                crawlblock.songurl = href
                crawlblock.cover_art_url = ""
                mdlinks.append(Fav(name:crawlblock.name ?? "??", url:crawlblock.songurl,comment:""))
                recordExporter.addRowToExportStream(cont: crawlblock)
            }
        }
        
        // if we are writing md files for Publish
        if let aurl = crawlblock.albumurl {
            // figure out the coverarturl here, either take the default for the bandsite or take the first one in the mdlinks
            for alink in mdlinks {
               let x =  alink.url.components(separatedBy: ".").last ?? "fail"
                if lgFuncs.isImageExtension(x) {
                    crawlblock.cover_art_url = alink.url
                    break
                }
            }
            
            if crawlblock.cover_art_url == "" {
                crawlblock.cover_art_url = imgurl
            }
            
            let props = CustomPageProps(isInternalPage: false,
                                      urlstr: aurl,
                                      title: crawlblock.name ?? "???",
                                      tags:  pr.tags)
            
            return OnePageGuts(props: props,links: mdlinks)
            
        }//writemdfiles==true
        
        return nil
    }//incorporateParseResults

    
    func scraper( url theURL:URL,  html: String)   -> ParseResults? {
        
        // starts here
        if firstTime {
            recordExporter.addHeaderToExportStream()
            firstTime = false
        }
        
        do {
            assert(html.count != 0 , "No html to parse")
               // try lgfuncs(lgFuncs:lgFuncs,theURL: theURL,html: html,links: &links)
           let scrblock = try lgFuncs.scrapeRestore(lgFuncs,theURL,html )
            return  ParseResults(url: theURL,
                                 status: .succeeded, pagetitle: scrblock.title,
                                        links: scrblock.links, props:[], tags: [])
        }
        catch {
            print("cant parse \(theURL) error is \(error)")
            return  nil
        }
        
       
    }
}
