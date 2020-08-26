//
//  View.swift
//  Convex Hull
//
//  Created by Jaap Wijnen on 19/02/2017.
//  Copyright © 2017 Workmoose. All rights reserved.
//

import UIKit

typealias CGPoints = [CGPoint]
typealias LineSegments = [LineSegment]

extension CGPoint {
    func angle(to point: CGPoint) -> CGFloat {
        
        let originX = point.x - self.x
        let originY = point.y - self.y
        var radians = atan2(originY, originX)
        
        while radians < 0 {
            radians += CGFloat(2 * Double.pi)
        }
        
        return radians
    }
}

struct PointDistance {
    let point:CGPoint
    let distance:CGFloat
}

struct LineSegment {
    let from:CGPoint
    let to:CGPoint
    let deltaX:CGFloat
    let deltaY:CGFloat

    init(from:CGPoint, to:CGPoint) {
        self.from = from
        self.to = to
        self.deltaX = to.x - from.x
        self.deltaY = to.y - from.y
    }

    // TODO: move this out, so we don't call it multiple times
    func radians() -> CGFloat {
        from.angle(to: to)
    }

    func intersects(_ other:LineSegment) -> Bool {
        let determinant = deltaX * other.deltaY - other.deltaX * deltaY
        if abs(determinant) < 0.0001 {
             // if the determinant is effectively zero then the lines are parallel/colinear
             return false
        }

        // if the coefficients both lie between 0 and 1 then we have an intersection
        let ab = ((from.y - other.from.y) * other.deltaX - (from.x - other.from.x) * other.deltaY) / determinant

        if ab > 0 && ab < 1 {
            let cd = ((from.y - other.from.y) * deltaX - (from.x - other.from.x) * deltaY) / determinant

            if cd > 0 && cd < 1 {
                return true
            }
        }
        
        return false
    }
    
    func intersects(_ others:[LineSegment]) -> Bool {
        for line in others {
            if self.intersects(line) {
                return true
            }
        }
        return false
    }
    
    func segment(to next:CGPoint) -> LineSegment {
        return LineSegment(from: self.to, to: next)
    }
}

extension LineSegments {
    func sortedByAngle(from angle:CGFloat) -> LineSegments {
        return self.sorted { (a, b) -> Bool in
            a.radians() > b.radians()
        }
    }
}

extension Double {
    var asDegrees: Double { return self * 180 / .pi }
    var asRadians: Double { return self * .pi / 180 }
}

extension CGPoints {
    func sortedByX() -> CGPoints {
        return self.sorted { return $0.x < $1.x }
    }
    
    func nearest(to point:CGPoint) -> [CGPoint] {
        return self.map {
            PointDistance(point: $0, distance: pointDistance(from: $0, to: point))
        }
        .sorted { (a, b) -> Bool in
            a.distance < b.distance
        }
        .map {
            $0.point
        }
    }
    
    func headings(from point:CGPoint) -> [LineSegment] {
        return self.map {
            LineSegment(from: point, to: $0)
        }
    }
    
    func intersects(_ segment:LineSegment) -> Bool {
        return false
    }
}

func pointDistance(from a: CGPoint, to b: CGPoint) -> CGFloat {
    let xDist = a.x - b.x
    let yDist = a.y - b.y
    return CGFloat(sqrt(xDist * xDist + yDist * yDist))
}

func ConcaveHull(_ rawPoints:[CGPoint], k:Int) -> [CGPoint] {
    if rawPoints.count <= 3 {
        return rawPoints
    }
    let kInc = k // Increment k to expand search distance
    var points = rawPoints.sortedByX()
    print("starting with \(points)")
    var path = [CGPoint]()
    var segments = [LineSegment]()
    
    path.append(points.first!)
    // Special start segment points to itself, will be replaced
    segments.append(LineSegment(from: path.first!, to: path.first!))
    
    points.removeFirst()
    print("removed first \(path.first!)")
    print("leaving \(points)")

    while !points.isEmpty {
        var workingK = k
        while true {
            let nearest = CGPoints(points
                .nearest(to: path.last!)
                .prefix(workingK))
                .headings(from: path.last!)
                .sortedByAngle(from: 0.0)
            if nearest.isEmpty {
                fatalError()
            }
            print("nearest \(nearest.count) of \(points.count) \(nearest)")
            var nextSegment:LineSegment?
            for candidateSegment in nearest {
                print("candidateSegment \(candidateSegment)")
                //let candidate = segments.last!.segment(to: candidateSegment.to)
                if candidateSegment.intersects(segments.dropLast()) {
                    print("line cross \(candidateSegment)")
                    continue
                }
                nextSegment = candidateSegment
                break
            }
            if let nextSegment = nextSegment {
                segments.append(nextSegment)
                path.append(nextSegment.to)
                if let nextPointIndex = points.index(of: nextSegment.to) {
                    points.remove(at: nextPointIndex)
                } else {
                    fatalError("missing \(nextSegment.to) from \(points)")
                }
                print("selected \(nextSegment)")
                // HACK
                return path
                break
            } else {
                print("size check \(nearest.count) \(points.count)")
                if nearest.count >= points.count {
                    print("Failed")
                    return path
                    //fatalError()
                }
                workingK += kInc
                print("failed, expanding workingK to \(workingK)")
            }
        }

    }

    // Back to start
    //path.append(path.first!)

    return path
}

struct ConvexHull {
    let hull:CGPoints
    
    init(_ points:CGPoints) {
        // Assume points has at least 2 points
        var pts = points.sortedByX()
        let p1 = pts.removeFirst()
        let p2 = pts.removeLast()
        let (s1, s2) = ConvexHull.split(points: pts, p1: p1, p2: p2)
        var result:CGPoints = [p1, p2]
        result = ConvexHull.findHull(hull: result, points: s1, p1, p2)
        result = ConvexHull.findHull(hull: result, points: s2, p2, p1)
        self.hull = result
    }
    
    static func findHull(hull:CGPoints, points: CGPoints, _ p1: CGPoint, _ p2: CGPoint) -> CGPoints {
        // if set of points is empty there are no points to the right of this line so this line is part of the hull.
        if points.isEmpty {
            return hull
        }
        
        var newHull = hull
        var pts = points
        let furthestPoint = ConvexHull.furthest(points: pts, from: (p1, p2))

        newHull.insert(furthestPoint, at: newHull.index(of: p1)! + 1) // insert point with max distance from line in the convexHull after p1
        pts.remove(at: pts.index(of: furthestPoint)!) // remove furthestPoint from points array as we are going to split this array in points left and right of the line
        
        // points to the right of oriented line from p1 to maxPoint
        var s1 = CGPoints()
        
        // points to the right of oriented line from maxPoint to p2
        var s2 = CGPoints()
        
        // p1 to maxPoint line
        let lineVec1 = CGPoint(x: furthestPoint.x - p1.x, y: furthestPoint.y - p1.y)
        // maxPoint to p2 line
        let lineVec2 = CGPoint(x: p2.x - furthestPoint.x, y: p2.y - furthestPoint.y)
        
        for p in pts {
            let pVec1 = CGPoint(x: p.x - p1.x, y: p.y - p1.y) // vector from p1 to p
            let sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y // sign to check is p is to the right or left of lineVec1
            
            let pVec2 = CGPoint(x: p.x - furthestPoint.x, y: p.y - furthestPoint.y) // vector from p2 to p
            let sign2 = lineVec2.x * pVec2.y - pVec2.x * lineVec2.y // sign to check is p is to the right or left of lineVec2
            
            if sign1 > 0 { // right of p1 maxPoint line
                s1.append(p)
            } else if sign2 > 0 { // right of maxPoint p2 line
                s2.append(p)
            }
        }
        
        // find new hull points
        newHull = ConvexHull.findHull(hull: newHull, points: s1, p1, furthestPoint)
        newHull = ConvexHull.findHull(hull: newHull, points: s2, furthestPoint, p2)
        return newHull
    }

    
    static func furthest(points:CGPoints, from line: (CGPoint, CGPoint)) -> CGPoint {
        let distances = points.map {
            return (ConvexHull.distance(from: $0, to: (line.0, line.1)), $0)
        }.sorted { $0.0 < $1.0 }
        return distances.last!.1
    }
    

    static func distance(from p: CGPoint, to line: (CGPoint, CGPoint)) -> CGFloat {
        // If line.0 and line.1 are the same point, they don't define a line (and, besides,
        // would cause division by zero in the distance formula). Return the distance between
        // line.0 and point p instead.
        if line.0 == line.1 {
            return sqrt(pow(p.x - line.0.x, 2) + pow(p.y - line.0.y, 2))
        }
        
        // from Deza, Michel Marie; Deza, Elena (2013), Encyclopedia of Distances (2nd ed.), Springer, p. 86, ISBN 9783642309588
        return abs((line.1.y - line.0.y) * p.x
            - (line.1.x - line.0.x) * p.y
            + line.1.x * line.0.y
            - line.1.y * line.0.x)
            / sqrt(pow(line.1.y - line.0.y, 2) + pow(line.1.x - line.0.x, 2))
    }
    
    static func split(points:CGPoints, p1:CGPoint, p2:CGPoint) -> (CGPoints, CGPoints) {
        // points to the right of oriented line from p1 to p2
        var s1 = CGPoints()
        
        // points to the right of oriented line from p2 to p1
        var s2 = CGPoints()
        
        // p1 to p2 line
        let lineVec1 = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
        for p in points { // per point check if point is to right or left of p1 to p2 line
            let pVec1 = CGPoint(x: p.x - p1.x, y: p.y - p1.y)
            let sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y // cross product to check on which side of the line point p is.
            
            if sign1 > 0 { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
                s1.append(p)
            } else { // right of p2 p1 line
                s2.append(p)
            }
        }
        return (s1, s2)
    }
}

class View: UIView {
    
    let MAX_POINTS = 10
    var _points = [CGPoint]()
    var _convexHull = [CGPoint]()
    var _concaveHull = [CGPoint]()

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

    var points3:[CGPoint] {
        return [(59, 434), (145, 498), (176, 418), (216, 624), (268, 567), (283, 88), (283, 560), (298, 338), (315, 133), (323, 499)].map {
            CGPoint(x:$0.0, y:$0.1)
        }
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _points = points3
        //_points = generateRandomPoints()
        //print("\(_points)")
        //_convexHull = quickHull(points: _points)
        let s = ConvexHull(_points)
        _convexHull = s.hull
        _concaveHull = ConcaveHull(_points, k: 3)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func generateRandomPoints() -> [CGPoint] {
        var result = [CGPoint]()
        for _ in 0..<MAX_POINTS {
            let offset: CGFloat = 50
            let xrand = CGFloat(arc4random()) / CGFloat(UInt32.max) * (self.frame.width - offset) + 0.5 * offset
            let yrand = CGFloat(arc4random()) / CGFloat(UInt32.max) * (self.frame.height - offset) + 0.5 * offset
            let point = CGPoint(x: xrand, y: yrand)
            result.append(point)
        }
        
        result.sort { (a: CGPoint, b: CGPoint) -> Bool in
            return a.x < b.x
        }
        return result
    }

    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        // Draw hull
        let lineWidth: CGFloat = 2.0
        
        context!.setFillColor(UIColor.black.cgColor)
        context!.setLineWidth(lineWidth)
        context!.setStrokeColor(UIColor.red.cgColor)
        context!.setFillColor(UIColor.black.cgColor)

        if true {
            let firstPoint = _convexHull.first!
            context!.move(to: firstPoint)
            for p in _convexHull.dropFirst() {
                context!.addLine(to: p)
            }
            context!.addLine(to: firstPoint)
        } else {
            let curvePoints = _convexHull + [_convexHull.first!]
            context!.move(to: curvePoints.first!)
            for segment in cubicCurveSegments(from: curvePoints) {
                context!.addCurve(to: segment.end, control1: segment.startControl, control2: segment.endControl)
            }
        }
        
        context!.strokePath()
        
        if true && !_concaveHull.isEmpty {
            context!.setStrokeColor(UIColor.blue.cgColor)
            let firstPoint = _concaveHull.first!
            context!.move(to: firstPoint)
            for p in _concaveHull.dropFirst() {
                context!.addLine(to: p)
            }
            context!.addLine(to: firstPoint)
            context!.strokePath()
        }
        
        // Draw points
        for p in _points {
            let radius: CGFloat = 5
            let circleRect = CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius)
            context!.fillEllipse(in: circleRect)
        }
    }
}
