//
//  runStruct.swift
//  interStellarTest
//
//  Created by sami on 2017/11/10.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation


enum mapFilteringMode {
    
    case personal   //my personals combined
    case world  //everything that comes in combined
    case localCompetition   //group by clan
    
}



struct Runs {
    
    var o : [Run] = []
    
    func readByUser (user: String) -> Runs? {
        
        
        let n =  o.filter { $0.user == user }
        if n.count == 0 { return nil }
        
        var no = Runs()
        for i in n {
            
            no.append(run: i)
            
        }
        
        return no
    }
    
    func readByClan (clan: String) -> Runs? {
        
        
        let n =  o.filter { $0.clan == clan }
        if n.count == 0 { return nil }
        
        var no = Runs()
        for i in n {
            
            no.append(run: i)
            
        }
        
        return no
    }
    
    func readUniqueUsers () -> [String]? {
    
        let upc = o.map{ $0.user }
        //let newArray : [String] = o.filter { !o.user.contains($0) }
        let newArray = Array(Set(upc))
        return newArray
    }
    
    func readUniqueClans () -> [String]? {
        
        let upc = o.map{ $0.clan }
        //let newArray : [String] = o.filter { !o.user.contains($0) }
        let newArray = Array(Set(upc))
        return newArray
    }
    
    func allSorted () -> Runs? {
        
        let n = o.sorted()
        
        if n.count == 0 { return nil }
        
        var no = Runs()
        for i in n {
            
            no.append(run: i)
            
        }
        
        return no
    }
    
    mutating func appendMany ( runs : [Run]) {
        
        for run in runs {
            _ = self.append(run : run)
        }
        
    }
    
    mutating func append (run : Run ) -> Bool {
        
        if run.coordinates.count < 5 { return false }
        if run.coordinates.count > 5000 { return false }
        if run.user == "feederbot@hastur.org" { return false }
        o.append(run)
        return true
    }
    
    func getWithinArea ( lat : CLLocationDegrees, lon : CLLocationDegrees , distanceInMeters : Double ) -> Runs? {
    
        let location2 = CLLocation(latitude: lat, longitude: lon)
        
        var withinRange = Runs()
        
        for f in o {
            if let loca = Geohash.decode(f.geoHash) {
                let location1 = CLLocation(latitude: loca.latitude, longitude: loca.longitude)
            
                let d = location1.distance(from: location2) as Double;
                if d == 0 { continue }
                if d < distanceInMeters {
                
                    withinRange.append(run: f)
                }
            }
        }
        
        if withinRange.o.count == 0 { return nil }
        
        return withinRange
    
    } //getWithinArea
}

extension Run : Comparable {
    
    static func == (lhs: Run, rhs: Run) -> Bool {
        return lhs.startTime == rhs.startTime
    }
    
    static func < (lhs: Run, rhs: Run) -> Bool {
        return lhs.startTime < rhs.startTime
    }
    
}

struct coordinate : Codable {
    
    let timestamp : Double
    /*let plugged : Int
     let level : Int
     let error : Int*/
    let lat : CLLocationDegrees
    let lon : CLLocationDegrees
    //let temperature : Int
    
    
}

struct Run : Codable {
    
    let missionID : Double
    let user : String
    let clan : String
    //let timestamp : Double
    /*let plugged : Int
    let level : Int
    let error : Int
    let temperature : Int*/
    var geoHash : String
    let version : String
    let hash : String
    let startTime : Double
    var closeTime : Double
   
    var coordinates : [coordinate]
    
    mutating func finalizeRun () {
        
        //called when personal run closes
        let lac = self.coordinates.last
        self.closeTime = lac!.timestamp;
        let gh = Geohash.encode(latitude: lac!.lat, longitude: lac!.lon)
        self.geoHash = gh;
        
    }
    
    var totalTime : Double {
    
        return closeTime - startTime
    }
    
    //adding rounding of coordinates here would distort the run
    func getHash () -> String {
        
        return String(closeTime.hashValue ^ user.hashValue ^ geoHash.hashValue)
        
    }
    
    func computeGeoHash () -> String {
        
        if coordinates.isEmpty {
            
            return "invalidGeoHash";
            
        }
        
        let lat = coordinates.last!.lat as Double;
        let lon = coordinates.last!.lon as Double;
        
        let gh = Geohash.encode(latitude: lat, longitude: lon)
        return gh;
        
    }
    
    mutating func addCoordinate (coord : coordinate ) -> Bool {
        
        if coordinates.isEmpty {
            coordinates.append(coord)
            closeTime = coord.timestamp
            return true
        }
        //are we too close
        let location1 = CLLocation(latitude: (coord.lat), longitude: (coord.lon))
        let location2 = CLLocation(latitude: (coordinates.last?.lat)!, longitude: (coordinates.last?.lon)!)
        let d = location1.distance(from: location2) as Double;
        if (d<10){ return false }
        
        //time based filtering too?
        
        coordinates.append(coord)
        closeTime = coord.timestamp
        
        let gh = Geohash.encode(latitude: coord.lat, longitude: coord.lon)
        self.geoHash = gh;
        
        return true
    }
    
    func spikeFilteredCoordinatesKALMANbroken () -> [coordinate]? {
        
        if self.coordinates.isEmpty {
            return nil
        }
        
        if self.coordinates.count < 10 {
            return nil
        }
        
        let lastCoord = coordinates.last;
        let loc2D = CLLocationCoordinate2D(latitude: lastCoord?.lat as! CLLocationDegrees, longitude: lastCoord?.lon as! CLLocationDegrees);
        
        let date = Date(timeIntervalSince1970: 0)
        
        let initLoc = CLLocation(coordinate: loc2D, altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 0, timestamp: date);
        
        
        
        let hcKalmanFilter = HCKalmanAlgorithm(initialLocation: initLoc);
        
        let rcoord = self.coordinates.reversed()
        
        var kalCoords = [coordinate]();
        var ff : Double = 1;
        
        for f in rcoord {
            
            let zloc2D = CLLocationCoordinate2D(latitude: f.lat as! CLLocationDegrees, longitude: f.lon as! CLLocationDegrees);
            
            let zdate = Date(timeIntervalSince1970: ff)
            ff = ff + 1 ;
            
            let loc = CLLocation(coordinate: zloc2D, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0, timestamp: zdate);
            
            
            if let kalmanLocation : CLLocation? = hcKalmanFilter.processState(currentLocation: loc){
                
                if let ll = kalmanLocation?.coordinate { //kal filtered coordo
                
                    let org = CLLocation(latitude: (f.lat), longitude: (f.lon));
                    let fixed = CLLocation(latitude: (ll.latitude), longitude: (ll.longitude));
                    if let d = org.distance(from: fixed) as Double? {
                    
                        print(d);
                        if d < 80 {
                        
                            let nc : coordinate = coordinate(timestamp :f.timestamp ,lat:ll.latitude,lon:ll.longitude)
                            kalCoords.append(nc)
                        }
                    
                    }
                }   //getting a kalmann coord are we
            }
            
            
            
        }
        if kalCoords.count < 3 { return nil; }
        
        let dif = self.coordinates.count - kalCoords.count
        print (dif);
        
        return kalCoords;
    }
    
    
    func spikeFilteredCoordinates () -> [coordinate]? {
        
        if self.coordinates.isEmpty {
            return nil
        }
        
        if self.coordinates.count < 15 {
            return nil
        }
        
        var validCoords = [coordinate]()
        
        let rcoord = self.coordinates.reversed()
        var baseSpeed : Double = 0;
        var prevLocation = CLLocation(latitude:0,longitude:0)
        var prevTimestamp : Double = 0;
        var acceptedBaseSpeed : Double = 0;
        
        for i in rcoord {
            
            if baseSpeed == 0 {
                prevLocation = CLLocation(latitude: (i.lat), longitude: (i.lon))
                prevTimestamp = i.timestamp
                baseSpeed = 1;
                //trust the last coodrina
                validCoords.append(i)
                
                continue
                
            }
            
            let cur = CLLocation(latitude: (i.lat), longitude: (i.lon))
            let timDif = prevTimestamp - i.timestamp
            let d = cur.distance(from: prevLocation) as Double;
            let timVar = d / timDif
            
            baseSpeed = baseSpeed + timVar;
            //print (d)
            //print (timVar)
            if timVar < 40 && d < 95 {
                //if baseSpeed == 1 {
                    validCoords.append(i)
                    acceptedBaseSpeed = acceptedBaseSpeed + timVar
                    prevLocation = CLLocation(latitude: (i.lat), longitude: (i.lon))
                //}
                continue;
            }
            
            
        }
        print (rcoord.count)
        print (validCoords.count)
        let avgBaseSpeed = baseSpeed / Double(rcoord.count)
        let accavgBaseSpeed = acceptedBaseSpeed / Double(validCoords.count)
        
        //print ("avg base speed \(avgBaseSpeed ) with \(rcoord.count ) cooridnates, acccepted \(accavgBaseSpeed ) " )
        
        /*if avgBaseSpeed >  0.0062 {
            
            let accavgBaseSpeed = acceptedBaseSpeed / Double(validCoords.count)
            if accavgBaseSpeed > 0.0035 {
                return nil
                }
            
            }*/
        
        //the area can be valid with a very few points
        if validCoords.count < 10 {
            return nil;
        }
        
        return validCoords
        
    }
    
    func isReadyForTemporarySave () -> Bool {
        
        //disk writer wants to save this. ignore if the run is not long enough
        if self.totalDistance() < 100 {
            
            return false;
        }
        
        
        return true;
    }
    func totalDistance () -> Double {
        
        guard let pp = spikeFilteredCoordinates() else {
            return 0;
        }
        
        var td : Double = 0;
        let latitude: CLLocationDegrees = 37.2
        let longitude: CLLocationDegrees = 22.9
        var preLoc = CLLocation(latitude: (latitude), longitude: (longitude))
        var eka = false;
        
        for f in pp {
            
            let loc = CLLocation(latitude: (f.lat), longitude: (f.lon))
            if !eka {
                eka = true
                preLoc = loc
                continue
            }
            
            let noc = CLLocation(latitude: (f.lat), longitude: (f.lon))
            let d = noc.distance(from: preLoc) as Double;
            td = td + d
            preLoc = noc
        }
        
        return td
        
    }
    
    var isValid: Bool {
    get {
        if coordinates.count < 10 { return false }
        if coordinates.count > 5000 { return false; }
        if user == "feederbot@hastur.org" {
            return false }
        if user == "mapfeeder@hastur.org" {
            return false }
        if startTime < 125000000 { return false; }
        if closeTime < 125000000 { return false; }
        return true
        }
        
    }
    
    func distanceBetweenStartAndEndSpikeFiltered () -> Double {
        
        if coordinates.count < 10 { return 999999 }
        
        guard let pp = spikeFilteredCoordinates() else {
            return 999999;
        }
        
        let location1 = CLLocation(latitude: (pp.first?.lat)!, longitude: (pp.first?.lon)!)
        let location2 = CLLocation(latitude: (pp.last?.lat)!, longitude: (pp.last?.lon)!)
        
        let d = location1.distance(from: location2) as Double;
        
        return d;
    }
    
    func isClosed () -> Bool {
        
        if coordinates.count < 10 { return false }
        
        guard let pp = spikeFilteredCoordinates() else {
            return false;
        }
        
        
        let location1 = CLLocation(latitude: (pp.first?.lat)!, longitude: (pp.first?.lon)!)
        let location2 = CLLocation(latitude: (pp.last?.lat)!, longitude: (pp.last?.lon)!)
        
        let d = location1.distance(from: location2) as Double;
        let totDist = totalDistance();
        if  totDist < 350 {
            
            return false
            
        }
        
        //1km gives 100m extra, 5km would be 500 closing radius
        
        let gap = 50 + ((totDist / 1000)*100);
        
        if d > gap {
            
            return false
            
        }
        
        
        
        return true
        
    }   //end of isClosed
    
    func round(_ value: Double, toDecimalPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return Darwin.round(value * divisor) / divisor
    }
    
    func simplify ( tolerance : Float ) -> [CLLocationCoordinate2D]? {
        
        
        //24.200481
        //65.822289999999995
        var points : [CLLocationCoordinate2D] = []
        for co in coordinates {
            
            //points.append(CLLocationCoordinate2D( latitude: CLLocationDegrees(round(co.lon,toDecimalPlaces: 5)), longitude: CLLocationDegrees(round(co.lat,toDecimalPlaces: 5)) ))
            points.append(CLLocationCoordinate2D( latitude: CLLocationDegrees(co.lon), longitude: CLLocationDegrees(co.lat) ))
            
        }
        
        let simplified = SwiftSimplify.simplify(points, tolerance: tolerance, highQuality: false)
        
        /*print ("simplifiCATION tolerance \(tolerance)")
        print(points.count)
        print(simplified.count)*/
        return simplified
        
    }
    
}   //end of run


class jsonBufferScanner : BufferConsumer {
    
    var queue = DispatchQueue(label: "jsonBufferDataQueue")
    var data = String();
    
    var inpipe = String();
    
    
    var buffer : String = "";
    var prefill = false;
    
    
    func addObject(text: String) -> Void {
        queue.sync {
            
            /*if self.processing {
                print("DROP ping add object jsonbuffercsa")
                return
                
            }    //just drop when we are busy
 
            */
            self.inpipe = self.inpipe + text;
            
            if self.inpipe.count > 150000 {
                
                if let validData = self.preProcessInpipe(data:self.inpipe) {
                    
                    self.data = validData;
                    self.inpipe = "" ;
                    
                } else {
                    
                    self.data = "";
                    self.inpipe = "" ;
                    
                }
                
            }   //pipe full enough?
            
        }   //end queue sync
        
    }
    
    func shiftInpipeDEPRE () {
        
        if self.processing {
            return;
        }
        queue.sync {
            
            self.data = String(self.inpipe);
            self.inpipe = "" ;
        }
        
        
    }
    
    func preProcessInpipe ( data : String ) -> String? {
        
        //just look for valid json strings
        let jss = data.unescaped; //convert to string
        let tit = jss.replacingOccurrences(of: "\\", with: "")
        
        guard let idp = self.findIDpiece(txt : tit) else {
            
            return nil;
        
        }
        
        //so ipd contains {"_ and onwards
        return idp;
        
    }
    
    
    
    
    func processBuffers (data : String ) -> [Run]? {
    
        var validStuff = [Run]()
        
        var found = false;
        
        
        if let validStrings = self.searchJson(data: data) {
            
            
            for f in validStrings {
                
                
                
                
                if let ro = createRunObject(jsonString: f){
                    
                    validStuff.append(ro);
                    found = true
                    
                }
                
                
            }
            
            
            totalSuccessfullBuffers = totalSuccessfullBuffers + 1
            
            print(validStrings);
            let mum = 1;
            
        } else {
            
            var tum = 1;
            
        }
        
        /*if let gn = self.searchJson(data: self.data) {
            found = true
            totalSuccessfullBuffers = totalSuccessfullBuffers + 1
        
            validStuff.append(gn)
        
        } else {
    
            var tum = 1;
    
        }*/
        
        if !found { return nil }
        
        return validStuff;
        
    }
    
    
    var brb = false;
    
    /*
    func searchFromMultipleEntries (entries : [String]) -> [Run?]? {
    
        var validStuff = [Run?]()
        buffer = ""
        prefill = false;
        var found = false
        if brb {
            print("caatc")
        }
        brb = true;
        let firb = entries;
        
        for fxf in firb {
            
            totalPassedBuffers = totalPassedBuffers + 1
            
            let fxfx = String(fxf);
            
            if terminated {
                return nil
                
            }
            if let gn = self.searchJson(data: fxfx) {
                found = true
                totalSuccessfullBuffers = totalSuccessfullBuffers + 1
                
                validStuff.append(gn)
                
            } else {
                
                var tum = 1;
                
            }
            
            
            //print(fxf)
            
        }   //loop all entries
        
        brb = false;
        
        if validStuff.count == 0 {
            return nil
            
        }
        //print (validStuff.count)
        //print ("searchFromMultipleEntries hits ")
        
        totalParsedObjects = totalParsedObjects + 1
        
        return validStuff
    
    }   */
    
    func searchJson ( data : String )  -> [String]? {
        
        var jsons = [String]();
        //any leftovers from last round. preprocess will cut leftovers tho
        //the leftovers are used when calling this recursively
        //let lookingAt = buffer + data;
        let lookingAt =  data;
        
        //print(lookingAt);
        //our stuff is already unescaped in preProcess
        //our stuff starts with {
        if let co = findCompleteJSONobject(zut: data) {
            
            //index 0 where to start looking, index1 where we end
            let ma = 1
            
            
            let indexS = lookingAt.index(lookingAt.startIndex, offsetBy: co[0])
            let indexE = lookingAt.index(lookingAt.startIndex, offsetBy: co[1])
            
            let xjss = lookingAt[indexS..<indexE]
            
            let indexS2 = lookingAt.index(lookingAt.startIndex, offsetBy: co[1])
            
            
            let xjss2 = lookingAt[indexS2..<lookingAt.endIndex]
            let remainders = String(xjss2);
            
            //let cleaned = String(xjss).unescaped; //convert to string
            //let tit = cleaned.replacingOccurrences(of: "\\", with: "")
            
            jsons.append(String(xjss));
            
            if remainders.count < 30000 {
                return jsons;
            }
            
            if let ca = self.searchJson(data: remainders) {
                
                //append result to
                print (ca.count);
                jsons.append(ca.first!)  // will give one entry
                //print(jsons);
                return jsons;
                
            } else {
                
                return jsons;
                
            }
            
        } else {
            
            return nil;
        }
        
    }
    
    //func splitToIndividualJsons ( data : String)
    
    func searchJsonDEPRE ( a : String )  -> Run? {
        //print(a);
        let jss = a.unescaped; //convert to string
        let tit = jss.replacingOccurrences(of: "\\", with: "")
        //let tit = a
        var lookingAt = "";
        
        if prefill {
            
            //too much data on a buffer to screen, wipe it out
            
            if buffer.count > 100000 {
                buffer = "";
            }
            prefill = false;
        }
        
        if !prefill {
            
            if let idp = findIDpiece(txt: tit) {
                //print(idp);
                lookingAt = idp
                
                if let co = findCompleteJSONobject(zut: idp) {
                    
                    print(co);
                    let tu=1;
                }
                
            } else {
                
                //junk belonging to prev mess, drop it
                buffer = ""
                return nil;
                
            }
            
        } else {
            
            
            
            //dump this me on top of watever came before
            //this buffer grows insanely big
            buffer = buffer + tit
            
            //look for beginning clues
            if let idp = findIDpiece(txt: buffer) {
                
                lookingAt = idp
                
            } else {
                
                //no id pieces on either block, discard
                buffer = ""
                prefill = false;
                return nil;
                
            }
            
        }   //prefilled data
        
        //print (lookingAt)
        
        //try to fish out something from lookingAt
        //if success, produce a bunch of objects
        if let co = findCompleteJSONobject(zut: lookingAt) {
            
            //index 0 where to start looking, index1 where we end
            let ma = 1
            
            
            let indexS = lookingAt.index(lookingAt.startIndex, offsetBy: co[0])
            let indexE = lookingAt.index(lookingAt.startIndex, offsetBy: co[1])
            
            let xjss = lookingAt[indexS..<indexE]
            
            let indexS2 = lookingAt.index(lookingAt.startIndex, offsetBy: co[1])
            
            
            let xjss2 = lookingAt[indexS2..<lookingAt.endIndex]
            let xjmaa = String(xjss2);
            if xjmaa.count < 100000 {
            
                buffer = xjmaa;
                prefill = true
                
            } else {
                //dont allow tons of crap on the buffer
                buffer = "";
                prefill = false;
            }
            
            //buffer = String(xjss2); //store for the future
            
            let xjS = String(xjss);
            
            if let ro = createRunObject(jsonString: String(xjS)){
            //if testForValidJson(jsonString: xjss) {
                
                //print("legit json")
                return (ro)
                
            } else {
                
                //print (xjss)
                print("crap json")
                return nil
            }
            
        
        } else {
            
            //print ("skip incomplete json but added to buffer")
            //buffer = buffer + lookingAt
            //prefill = false;
            buffer = "";    //clear buffer, it was full of crap anyway
            
        }
        
        return nil
    }
    
    func findCompleteJSONobject ( zut : String ) -> [Int]? {
        
        var i = -1;
        let zl = zut.count;
        var openBrackets = 0;
        var firstOpen = false;
        var grabbedObjects = [String]()
        var startI = 0;
        var endI = 0;

        print ("zut length \(zl) " )
        //print (zut);
        for m in zut {
            
            i = i + 1
            
            //skip fluff before an object
            /*if m == "}" && openBrackets == 0 && !firstOpen {
             
             continue;
             }*/
            
            if m == "{" && (openBrackets == 0) && !firstOpen {
                
                firstOpen=true;
                openBrackets = openBrackets+1
                startI = i;
                //print ("init opened section {")
                //print (openBrackets)
                continue
            }
            
            if m == "{" && openBrackets > 0  {
                
                openBrackets=openBrackets+1
                //print ("opened section {")
                //print (openBrackets)
                continue
            }
            
            
            //get closer to full objects
            if m == "}" && firstOpen {
                
                openBrackets=openBrackets-1
                
                //print (openBrackets)
                
                if openBrackets > 0 {
                    //print ("closed section }")
                    
                    continue;
                }
                
                if (startI == 0 && i == 0) {
                //bug catch
                    _ = findCompleteJSONobject(zut: zut)
                    
                }
                //return [startI,i]
                return [startI,i+1]
            }
            
                
            }
            
        return nil
        
    }
    
    func findIDpiece ( txt : String ) -> String? {
        
        let ni = txt.split(separator: "{");
        if ni.count == 1 { return nil }
        
        var unsco = 0;
        var unscoFound = false;
        var cutoff = 0;
        
        for f in ni {
            
            let na = f.split(separator: "_")
            if na.count > 1 {
                //we found our _id
                unscoFound = true;
                break
            }
            cutoff = cutoff + f.count;
            unsco = unsco + 1;
        }
        
        //we did not find _id
        if !unscoFound { return nil }
        
        let indexS = txt.index(txt.startIndex, offsetBy: cutoff)
        let indexE = txt.index(txt.endIndex, offsetBy : 0);
        let jss = txt[indexS..<indexE]
        
        return String(jss);
        
        let na = jss.split(separator: "}");
        
        var rest = "{";
        
        var openings = 0
        while unsco < na.count {
        //while unsco < ni.count {
            rest = rest + na[unsco] + "{";
            unsco = unsco + 1
            
        }
        
        return rest
        
        var begFound = false;
        var zut = ""
        let alen = txt.count - 5;
        
        var i = -1;
        for m in txt {
            
            if terminated { return nil }
            
            i = i + 1
            if (i > alen) { break }
            let indexS = txt.index(txt.startIndex, offsetBy: i+2)
            let indexE = txt.index(txt.startIndex, offsetBy: i+5)
            let jss = txt[indexS..<indexE]
            if jss == "_id" {
                let indexS = txt.index(txt.startIndex, offsetBy: i)
                
                let zat = txt[indexS..<txt.endIndex]
                
                return String(zat);
                
            }
            
            }   //look for start key
        
            return nil
        
        }
    
    func createRunObject (jsonString : String ) -> Run? {
        
        //print (jsonString);
        do {
            if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
                let json = try JSON(data: dataFromString)
                
                /*for (key,subJson):(String, JSON) in json {
                 // Do something you want
                 print (key)
                 print  (subJson)
                 }*/
                
                /*do {
                 // Decode data to object
                 
                 let jsonDecoder = JSONDecoder()
                 let run = try jsonDecoder.decode(Run.self, from: dataFromString)
                 print("Name : \(run.user)")
                 print("Clan : \(run.clan)")
                 }
                 catch {
                 
                 print ("bobek")
                 } */
                //let rco = json["coordinates"].dictionary
                let mid = json["closeTime"].doubleValue
                let st = json["startTime"].doubleValue
                let ct = json["closeTime"].doubleValue
                let user = json["user"].stringValue
                let clan = json["clan"].stringValue
                let geoh = json["geoHash"].stringValue
                let type = json["type"].stringValue
                let version = json["type"].stringValue
                
                //https://useyourloaf.com/blog/swift-hashable/
                //lame hash for now
                
                let hash = String(mid.hashValue ^ user.hashValue ^ geoh.hashValue)
                
                var run = Run(missionID: mid, user: user, clan: clan, geoHash: geoh, version : version , hash : hash , startTime: st, closeTime: ct, coordinates: [])
                
                
                
                var runCoords = [coordinate]();
                for (key,subJson):(String, JSON) in json["coordinates"] {
                    // Do something you want
                    //print (key)
                    //print  (subJson)
                    let times = subJson["timestamp"].doubleValue
                    let lat = subJson["x"].doubleValue
                    let lon = subJson["y"].doubleValue
                    let lala = CLLocationDegrees(lon);
                    let lolo = CLLocationDegrees(lat);
                    let rc = coordinate(timestamp: times , lat: lala , lon: lolo )
                    //runCoords.append(rc)
                    run.addCoordinate(coord: rc);
                    
                }
                
                
                
                return run
            }
            
        }
        catch _ {
            // Error handling
            let lip = 1;
        }
        
        return nil
        
    } //createRunObject
    
    func testForValidJson (jsonString : String ) -> Bool {
        
        
        
        
        do {
            if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
                let json = try JSON(data: dataFromString)
                let m = 1;
                
                /*for (key,subJson):(String, JSON) in json {
                    // Do something you want
                    print (key)
                    print  (subJson)
                }*/
                
                /*do {
                    // Decode data to object
                    
                    let jsonDecoder = JSONDecoder()
                    let run = try jsonDecoder.decode(Run.self, from: dataFromString)
                    print("Name : \(run.user)")
                    print("Clan : \(run.clan)")
                }
                catch {
                
                    print ("bobek")
                } */
                
                var runCoords = [coordinate]();
                for (key,subJson):(String, JSON) in json["coordinates"] {
                    // Do something you want
                    //print (key)
                    //print  (subJson)
                    let times = subJson["timestamp"].doubleValue
                    let lat = subJson["x"].doubleValue
                    let lon = subJson["y"].doubleValue
                    
                    let rc = coordinate(timestamp: times , lat: lat , lon: lon )
                    runCoords.append(rc)
                }
                
                //let rco = json["coordinates"].dictionary
                let mid = json["closeTime"].doubleValue
                let st = json["startTime"].doubleValue
                let ct = json["closeTime"].doubleValue
                let user = json["user"].stringValue
                let clan = json["clan"].stringValue
                let geoh = json["geoHash"].stringValue
                let type = json["type"].stringValue
                let version = json["type"].stringValue
                
                //https://useyourloaf.com/blog/swift-hashable/
                //lame hash for now
                
                let hash = String(mid.hashValue ^ user.hashValue ^ geoh.hashValue)
                
                let run = Run(missionID: mid, user: user, clan: clan, geoHash: geoh, version : version , hash : hash , startTime: st, closeTime: ct, coordinates: runCoords)
                
                
                
                //let jsonData = jsonString.data(using: .utf8)
                //let coordinates =  json["coordinates"].arrayValue.map({
                    
                    //$0["coordinate"].stringValue
                    
                    
                //})
                
                if JSONSerialization.isValidJSONObject(dataFromString) {
                    return true;
                } else {
                    return false
                }
                
                
                return true
            }
            
        }
        catch _ {
            // Error handling
            let lip = 1;
        }
        
        
        
        return false
        
        // return true;
        let jsonData = jsonString.data(using: String.Encoding.utf8)
        
        if JSONSerialization.isValidJSONObject(jsonData) {
            return true;
        } else {
            return false
        }
        
    }
    
    
}   //end jsonBufferScannerDER



//struct couchDBdoc : Cod
/*
{"timestamp":1431073615999,"plugged":0,"level":94,"error":16,"y":34.723671826182943789,
    "temperature":342,"x":135.28581968932905966}],"geoHash":"xn0jw920h","missionID":1431073613423}},
{"id":"0fc963bd6a141d0c0696d3311919810e","key":"0fc963bd6a141d0c0696d3311919810e",
    "value":{"rev":"2-f107f43a25a499bfb857e6f9dd79387c"},
    "doc":{"_id":"0fc963bd6a141d0c0696d3311919810e","_rev":"2-f107f43a25a499bfb857e6f9dd79387c",
        "sgps":2.5,"cumulatedRunTime":3303416,"maxLevel":0,"perimeter":4324,"hashCode":623796752,"timeZone":"GMT+09:00","type":"WANDERER","version":102,"startTime":1431680864605,"mgps":5,"closeTime":1431684168021,"area":268742870.662109375,"clan":"magistraatti","coordinateCount":616,"user":"samui@hastur.org",
        "coordinates":[{"timestamp":1431680878316,"plugged":0,"level":56,"error":6,"y":34.71919913838615912,"temperature":327,"x":135.28449111534644089},

*/

