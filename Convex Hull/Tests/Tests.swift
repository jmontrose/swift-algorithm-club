//
//  Tests.swift
//  Tests
//
//  Created by Matthew Nespor on 10/7/17.
//  Copyright © 2017 Workmoose. All rights reserved.
//

import XCTest

class Tests: XCTestCase {
    var points1:[CGPoint] {
        return [(43.019080134578765, 144.7073152274143), (134.6814073104601, 714.8075999924465), (156.45734513631493, 444.4761522159623), (220.21405908819617, 826.643071100964), (229.70594511849478, 273.3541207183977), (234.80897938688494, 66.11483188977346), (240.74277942714812, 591.5908375076463), (272.61688926620803, 717.1729678209342), (369.0258581815348, 282.3360639594812), (374.4740493701478, 723.403878344317)].map {
            CGPoint(x:$0.0, y:$0.1)
        }
    }
    
    var points2:[CGPoint] {
        return [(59.74721456569322, 434.1786262139628), (145.66965169847703, 498.9742737933933), (176.11009471190863, 418.41754885050875), (216.01836431655528, 624.3671417304704), (268.5646889637142, 567.2903060457413), (283.2745892205915, 88.33622698051302), (283.37187745756745, 560.5320654263562), (298.2737767606214, 338.7065549790176), (315.6066835333143, 133.42196905762466), (323.7445285773707, 499.53053317324503)].map {
            CGPoint(x:$0.0, y:$0.1)
        }
    }
    

    
  func testHorizontalInitialLine() {
    let view = View()
    let excludedPoint = CGPoint(x: 146, y: 284)
    let includedPoints = [
      CGPoint(x: 353, y: 22),
      CGPoint(x: 22, y: 22),
      CGPoint(x: 157, y: 447),
    ]

    view.points = [CGPoint]()
    view.convexHull = [CGPoint]()
    view.points.append(contentsOf: includedPoints)
    view.points.append(excludedPoint)
    view.points.sort { (a: CGPoint, b: CGPoint) -> Bool in
      return a.x < b.x
    }

    view.quickHull(points: view.points)

    assert(includedPoints.filter({ view.convexHull.contains($0) }).count == 3,
           "\(includedPoints) should have been included")
    assert(!view.convexHull.contains(excludedPoint),
           "\(excludedPoint) should have been excluded")
    }
}
