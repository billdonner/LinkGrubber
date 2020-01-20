
//
//  ManifezzClass: KrawlMaster 
//  UtilityTest
//
//  Created by william donner on 4/19/19.
//

import Foundation
import Kanna
 
let letters = CharacterSet.letters
let digits = CharacterSet.decimalDigits



func partFromUrlstr(_ urlstr:URLFromString) -> URLFromString {
    return urlstr//URLFromString(urlstr.url?.lastPathComponent ?? "partfromurlstr failure")
}

func kleenURLString(_ url: URLFromString) -> URLFromString?{
    let original = url.string
    let newer = original.replacingOccurrences(of: "%20", with: "+")
    return URLFromString(newer)
}

    func kleenex(_ f:String)->String {
        return f.replacingOccurrences(of: ",", with: "!")
    }

open class Fav {
   public let name: String
    public let url: String
   public  let comment: String
    public init (name:String = "",url:String = "",comment:String = "") {
        self.name = name
        self.url = url
        self.comment = comment
    }
}


open class LgFuncs {
    open class func isImageExtension (_ s:String) -> Bool {
    ["jpg","jpeg","png"].firstIndex(of: s) != nil
        }
    open class  func isAudioExtension (_ s:String) -> Bool {
    ["mp3","mpeg","wav"].firstIndex(of: s) != nil
    }
    open class  func isMarkdownExtension(_ s:String) -> Bool{
    ["md", "markdown", "txt", "text"].firstIndex(of: s) != nil
    }
}

final class  CrawlingElement:Codable {
    
    //these are the only elements moved into the output stream
    
    var name:String? = ""
    var artist:String? = ""
    var albumurl:String? = ""
    var songurl:String = ""
    var cover_art_url:String? = ""
    var album : String?  {
        if let alurl = albumurl {
            let blurl = alurl.hasSuffix("/") ? String( alurl.dropLast()  ) : alurl
            if  let aname = blurl.components(separatedBy: "/").last {
                return aname
            }
        }
        return albumurl
    }
}

 
final class Transformer:NSObject {
 
    struct Shredded {
        let letters: String
        let digits:String
    }

    
  func pickapart(_ phrase:String) -> Shredded {
     
    var letterCount = 0
    var digitCount = 0
    var lets:String = ""
    var digs:String = ""
    
    for uni in phrase.unicodeScalars  {
        if letters.contains(uni) {
            letterCount += 1
            lets += String(uni)
        } else if digits.contains(uni) {
            digitCount += 1
            digs += String(uni)
        }
    }
    return Shredded(letters:lets, digits:digs)
}
 
    var recordExporter : RecordExporter!
    var cont = CrawlingElement()
                             
    var firstTime = true
    let coverArtUrl : String?
    let artist : String
    
    var  bsProt: BandSiteProt
    
    
    func absorbLink(href:String? , txt:String? ,relativeTo: URL?, tag: String, links: inout [LinkElement]) {
        if let lk = href, //link["href"] ,
            let url = URL(string:lk,relativeTo:relativeTo) ,
            let linktype = processExtension(url:url, relativeTo: relativeTo) {
            
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

    required  init(artist:String,   recordExporter:RecordExporter,
                   bandSiteProt: BandSiteProt,
                   specialFolderPaths: [String],
        defaultArtUrl:String? = nil ) {
        self.bsProt  = bandSiteProt
        self.coverArtUrl = defaultArtUrl
        self.artist = artist
        self.recordExporter = recordExporter
        super.init()
        cleanOuputs(outpath:bsProt.pathToContentDir,specialFolderPaths: specialFolderPaths)
    }
    deinit  {
        recordExporter.addTrailerToExportStream()
        print("[crawler] finalized csv and json streams")
    }
    
    func  incorporateParseResults(pr:ParseResults,pageMakerFunc:MarkdownMakerSignature) throws {
        var mdlinks : [Fav] = []  // must reset each time !!
        // move the props into a record
        guard let url = pr.url else { fatalError() }
        for link in pr.links {
            let href =  link.href!.absoluteString
            if !href.hasSuffix("/" ) {
                cont.albumurl = url.absoluteString
                cont.name = link.title
                cont.songurl = href
                cont.artist = artist
                cont.cover_art_url = self.coverArtUrl
                mdlinks.append(Fav(name:cont.name ?? "??", url:cont.songurl,comment:""))
                recordExporter.addRowToExportStream(cont: cont)
            }
        }
        
        // if we are writing md files for Publish
        if let aurl = cont.albumurl {
            // figure out venue and playdate from the url
            
            let fund = url.lastPathComponent
            let shredded = pickapart(fund)
            let playdate = shredded.digits
            let venue = shredded.letters
            
            guard playdate != "" else {return}
            
            let ve =  venue == "" ? bsProt.venueShort: venue
            let month = playdate.prefix(2)
            let year = playdate.suffix(2)
            
            let start = playdate.index(playdate.startIndex, offsetBy: 2)
            let end = playdate.index(playdate.endIndex, offsetBy: -2)
            
            let day = playdate[start..<end]
            
            // when naming the file, put the date part first and then the venu, the date is YYMMDD for sorting
           
           // try Audio(bandfacts: bandSiteParams).makeAudioListMarkdown
            
            
//            try pageMakerFunc(mode: .fromPublish, url:aurl,
//                                      title: "\(playdate)\(venue)",
//                                        tags:["audio"],
//                                        p1: ve,
//                                        p2: String(year+month+day),
//                                      links:mdlinks )
            //.fromPublish
            try pageMakerFunc(  true,  aurl,    "\(playdate)\(venue)",  ["audio"],      ve,  String(year+month+day),  mdlinks )
        }//writemdfiles==true
    }//incorporateParseResults

    
    func scraper(_ parseTechnique:ParseTechnique, url theURL:URL,  html: String)   -> ParseResults? {
        
        var title: String = ""
        var links : [LinkElement] = []
        
        guard theURL.absoluteString.hasPrefix(bsProt.matchingURLPrefix.absoluteString) else
        {
            return nil
        }
        // starts here
        if firstTime {
            recordExporter.addHeaderToExportStream()
            firstTime = false
        }
         
        do {
            assert(html.count != 0 , "No html to parse")
            let doc = try  Kanna.HTML(html: html, encoding: .utf8)
            title = doc.title ?? "<untitled>"
            
            switch parseTechnique {
                
            case .parseTop,.parseLeaf:
                for link in doc.xpath("//a") {
                    absorbLink(href:link["href"],txt:link.text,relativeTo:theURL, tag: "media",links:&links )
                }
                
            case .indexDir:
                fatalError("forcedFailure induced")
                break;
            case .passThru:
                fatalError("forcedFailure induced")
            }
        }
        catch {
            print("cant parse error is \(error)")
            return  ParseResults(url: theURL,  technique: parseTechnique,
                                 status: .failed(code: 0), pagetitle:title,
                                 links: links, props: [], tags: [])
        }
        
        return  ParseResults(url: theURL, technique: parseTechnique,
                             status: .succeeded, pagetitle: title,
                             links: links, props:[], tags: [])
    }
}

//MARK: - pass thru the music and art files, only
extension Transformer {
    func processExtension(url:URL,relativeTo:URL?)->Linktype?{
        let pext = url.pathExtension.lowercased()
        let hasextension = pext.count > 0
        let linktype:Linktype = hasextension == false ? .hyperlink:.leaf
        guard url.absoluteString.hasPrefix(relativeTo!.absoluteString) else {
            return nil
        }
        
        if hasextension {
            guard LgFuncs.isImageExtension(pext) || LgFuncs.isAudioExtension(pext) else {
                return nil
            }
            if LgFuncs.isImageExtension(pext) || LgFuncs.isMarkdownExtension(pext) {
                print("Processing \(pext) file from \(url)")
            }
        } else
        {
            //  print("no ext: ", url)
        }
        return linktype
    }
    
    //MARK: - cleanup special folders for this site
    func cleanOuputs(outpath:String,specialFolderPaths:[String]) {
        do {
            // clear the output directory
            let fm = FileManager.default
            var counter = 0
            for folder in specialFolderPaths{
                
                let dir = URL(fileURLWithPath:outpath+folder)
                
                let furls = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                for furl in furls {
                    try fm.removeItem(at: furl)
                    counter += 1
                }
            }
            print("[crawler] Cleaned \(counter) files from ", outpath )
        }
        catch {print("[crawler] Could not clean outputs \(error)")}
    }
}
 
