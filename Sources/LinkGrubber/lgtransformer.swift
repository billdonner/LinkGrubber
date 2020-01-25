
//
//  ManifezzClass: KrawlMaster 
//  UtilityTest
//
//  Created by william donner on 4/19/19.
//

import Foundation
import Kanna



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


public class LgFuncs {
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
    private   var markdownExtensions:[String]
    init(imageExtensions:[String],audioExtensions:[String],markdownExtensions:[String]) {
        self.imageExtensions = imageExtensions
        self.audioExtensions = audioExtensions
        self.markdownExtensions = markdownExtensions
    }
    public static  func defaults() -> LgFuncs {
        return LgFuncs(imageExtensions: ["jpg","jpeg","png"],
                       audioExtensions: ["mp3","mpeg","wav"],
                       markdownExtensions: ["md", "markdown", "txt", "text"])
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
    var lgFuncs:LgFuncs
    var recordExporter : RecordExporter!
    var cont = CrawlingElement()
    var firstTime = true
    var fsProt: FileSiteProt
     
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
    
    required  init( recordExporter:RecordExporter,  fsProt: FileSiteProt , lgFuncs:LgFuncs) {
        self.fsProt  = fsProt
        self.lgFuncs = lgFuncs
        self.recordExporter = recordExporter
        super.init()
        cleanOuputs(baseFolderPath:fsProt.pathToContentDir,folderPaths: fsProt.specialFolderPaths)
    }
    deinit  {
        recordExporter.addTrailerToExportStream()
        print("[crawler] finalized csv and json streams")
    }
    
    func  incorporateParseResults(pr:ParseResults,pageMakerFunc:PageMakerFunc,imgurl:String="") throws {
        var mdlinks : [Fav] = []  // must reset each time !!
        // move the props into a record
        guard let url = pr.url else { fatalError() }
        
        for link in pr.links {
            let href =  link.href!.absoluteString
            if !href.hasSuffix("/" ) {
                cont.albumurl = url.absoluteString
                cont.name = link.title
                cont.songurl = href
                cont.cover_art_url = ""
                mdlinks.append(Fav(name:cont.name ?? "??", url:cont.songurl,comment:""))
                recordExporter.addRowToExportStream(cont: cont)
            }
        }
        
        // if we are writing md files for Publish
        if let aurl = cont.albumurl {
            // figure out the coverarturl here, either take the default for the bandsite or take the first one in the mdlinks
            for alink in mdlinks {
               let x =  alink.url.components(separatedBy: ".").last ?? "fail"
                if lgFuncs.isImageExtension(x) {
                    cont.cover_art_url = alink.url
                    break
                }
            }
            
            if cont.cover_art_url == "" {
                cont.cover_art_url = imgurl
            }
            
            let props = CustomPageProps(isInternalPage: false,
                                      urlstr: aurl,
                                      title: cont.name ?? "???",
                                      tags:  pr.tags)
            
            try pageMakerFunc( props, mdlinks)
            
        }//writemdfiles==true
    }//incorporateParseResults
    
    
    func scraper(_ parseTechnique:ParseTechnique, url theURL:URL,  html: String)   -> ParseResults? {
        
        var title: String = ""
        var links : [LinkElement] = []
        
        guard theURL.absoluteString.hasPrefix(fsProt.matchingURLPrefix) else
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
                    absorbLink(href:link["href"],
                               txt:link.text,
                               relativeTo:theURL,
                               tag: "media",links:&links )
                }
                
            case .indexDir:
                fatalError("forcedFailure induced")
                break;
//            case .passThru:
//                fatalError("forcedFailure induced")
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
            guard lgFuncs.isImageExtension(pext) || lgFuncs.isAudioExtension(pext) else {
                return nil
            }
            if lgFuncs.isImageExtension(pext) || lgFuncs.isMarkdownExtension(pext) {
                print("Processing \(pext) file from \(url)")
            }
        } else
        {
            //  print("no ext: ", url)
        }
        return linktype
    }
    
    //MARK: - cleanup special folders for this site
    func cleanOuputs(baseFolderPath:String,folderPaths:[String]) {
        do {
            // clear the output directory
            let fm = FileManager.default
            var counter = 0
            for folder in folderPaths{
                
                let dir = URL(fileURLWithPath:baseFolderPath+folder)
                
                let furls = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                for furl in furls {
                    try fm.removeItem(at: furl)
                    counter += 1
                }
            }
            print("[crawler] Cleaned \(counter) files from ", baseFolderPath )
        }
        catch {print("[crawler] Could not clean outputs \(error)")}
    }
}

