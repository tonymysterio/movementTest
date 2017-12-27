//
//  locationDataStorage.swift
//  movementTracker2
//
//  Created by sami on 2017/11/02.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import CoreLocation
//for recording individual points of CLLocation data
//record all data, raw and erroneous

//compare with coremotion events somewhere

//codable is typealias for encodable and decodable

struct dataPoint : Codable {
    
    let timestamp = Date().timeIntervalSince1970    //created when dataPoint was created
    var location = [CLLocationDegrees]()  //lat lon
    
    //CLLocationCoordinate2D
    
    //compare coreMotion event types separately
}
//pull kalman filtered, simplified data out
//check for run validity (core motion events), then filter and use data


//equal location, compare with another datapoint
extension dataPoint: Equatable {
    static func == (lhs: dataPoint, rhs: dataPoint) -> Bool {
        return lhs.location[0] == rhs.location[0] &&
            lhs.location[1] == rhs.location[1]
    }
}



struct dataPoints : Codable {
    
    var o = [dataPoint()] //array of datapoints
    let userID = ""     //useful when pushing to
    let minTimeDifference = 0.0
    let minAmountOfDataPoints = 10
    
    func totalTimeInMinutes () -> Double? {
        
        if o.count < minAmountOfDataPoints { return nil }
        //return time between first and last point
        let dif = o.last!.timestamp - o.first!.timestamp
        return dif
        
    }
    
    func kalmanFiltered () -> [dataPoint]? {
        
        //return nil if min amount of data points is not exceeded
        if o.count < minAmountOfDataPoints { return nil }
        
        var rdata = [dataPoint]()
        //clean out gps errors
        
        //kalman filtering and simplifying loses datapoints
        
        return rdata
        
    }
    
    func kalmanFilteredAndSimplified () -> [dataPoint]?  {
        
        //useful for throwing to map component
        if o.count < minAmountOfDataPoints { return nil }
        
        //swiftsimplify needs CLLocationCoordinate2D  
        
        var rdata = [dataPoint]()
        return rdata
        
    }
    
    
}

/*
 
 let json = """
 {
 "swifter": {
 "fullName": "Federico Zanetello",
 "id": 123456,
 "twitter": "http://twitter.com/zntfdr"
 },
 "lovesSwift": true
 }
 """.data(using: .utf8)! // our data in native format
 
 let myStruct = try JSONDecoder().decode(Swifter.self, from: json) // Decoding our data
 print(myStruct) // decoded!!!!! */

//pull push with
//https://medium.com/swiftly-swift/swift-4-decodable-beyond-the-basics-990cc48b7375
//disk persistent storage
//https://medium.com/@sdrzn/swift-4-codable-lets-make-things-even-easier-c793b6cf29e1


