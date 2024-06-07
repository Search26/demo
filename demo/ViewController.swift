//
//  ViewController.swift
//  demo
//
//  Created by iammai on 6/6/24.
//

import UIKit

class ViewController: UIViewController {
    
    private var radius: CGFloat = 150
    private var radius1: CGFloat = 0
    private var radius2: CGFloat = 30
    private var percentLabel: UILabel!
    private var latsPosition: CGPoint = .zero
    private var defaultPosition:CGPoint = .zero
    private var defaultBottomPosition:CGPoint = .zero
    private var centerCircle: CGPoint = .zero
    private var isDragging = false
    private var percentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let childView = createContentView()
        childView.center = self.view.center
        self.view.addSubview(childView)
        self.defaultPosition = CGPoint(x: (self.view.frame.midX), y: self.view.frame.midY - radius)
        self.defaultBottomPosition = CGPoint(x: (self.view.frame.midX), y: self.view.frame.midY + radius)
        self.latsPosition = defaultPosition
        self.resetView()
    }
    
    func createContentView() -> UIView {
        let container = UIView(frame: CGRect(origin: .zero, size: CGSize(width: radius * 2, height: radius * 2)))
        container.layer.cornerRadius = radius
        container.backgroundColor = .cyan
        
        let secondContainer = UIView(frame: CGRect(origin: .zero, size: CGSize(width: radius1 * 2, height: radius1 * 2)))
        secondContainer.layer.cornerRadius = radius1
        secondContainer.backgroundColor = .blue
        secondContainer.center = container.center
        self.percentView = secondContainer
        container.addSubview(secondContainer)
        
        let threeContainer = UIView(frame: CGRect(origin: .zero, size: CGSize(width: radius2 * 2, height: radius2 * 2)))
        threeContainer.layer.cornerRadius = radius2
        threeContainer.backgroundColor = .white
        threeContainer.center = container.center
        container.addSubview(threeContainer)
        
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: radius2 * 2, height: radius2 * 2)))
        label.textColor = .blue
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.text = "0%"
        label.center = container.center
        label.textAlignment = .center
        self.percentLabel = label
        container.addSubview(label)
        
        return container
    }
    
    func drawThumbnail(point: CGPoint) {
        let path = UIBezierPath(arcCenter: point,
                                radius: 10,
                                startAngle: 0,
                                endAngle: 2 * .pi,
                                clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = UIColor.blue.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.path = path.cgPath
        shapeLayer.name = "thumbNail"
        self.view.layer.addSublayer(shapeLayer)
        self.view.isUserInteractionEnabled = true
    }
    
    func drawCircle(endAngle: Double = 0, point: CGPoint) {
        self.view.layer.sublayers?.forEach {
            if let layer = $0 as? CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
        let path = UIBezierPath(arcCenter: self.centerCircle,
                                radius: radius,
                                startAngle: .pi * 3 / 2,
                                endAngle: endAngle + .pi * 3 / 2,
                                clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.blue.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.path = path.cgPath
        self.view.layer.addSublayer(shapeLayer)
        self.drawThumbnail(point: point)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        
        guard let point = touch?.location(in: self.view), let sublayers = self.view.layer.sublayers else { return }
        for sublayer in sublayers {
            if sublayer.name == "thumbNail" {
                guard let thumbNail = sublayer as? CAShapeLayer else { return }
                if let path = thumbNail.path, path.contains(point) {
                    self.isDragging = true
                    print("ntmlog isDragging\(true)")
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        
        guard let point = touch?.location(in: self.view) else { return }
        let isOnTopPart = self.checkIsTopPart(point)
        let isOnRightPart = self.checkIsOnRightPart(point)
        //prevent drag from 0% -> 99%
        if self.checkIsTopPart(self.latsPosition) && self.checkIsOnRightPart(self.latsPosition) && isOnTopPart && !isOnRightPart {
            self.isDragging = false
            self.resetView()
        }
        
        if self.checkIsTopPart(self.latsPosition) && !self.checkIsOnRightPart(self.latsPosition) && isOnTopPart && isOnRightPart {
            self.isDragging = true
        }
        
        self.latsPosition = point
        if !isDragging { return }
        if isOnRightPart {
            let angle = calculateAngleBetweenLines(A: (centerCircle.x, centerCircle.y), B: (defaultPosition.x, defaultPosition.y), C: (point.x, point.y))
            self.setPercent(Int(angle / (2 * .pi) * 100))
            guard let endPoint = self.intersectionOfCircleAndLine(C: (centerCircle.x, centerCircle.y), radius: radius, D: (point.x, point.y), angle: angle, defaultPoint: defaultPosition) else { return }
            print(endPoint)
            print("angle\(angle)")
            self.drawCircle(endAngle: angle, point: endPoint)
        } else {
            let angle = calculateAngleBetweenLines(A: (centerCircle.x, centerCircle.y), B: (defaultBottomPosition.x, defaultBottomPosition.y), C: (point.x, point.y)) + Double.pi
            self.setPercent(Int(angle / (2 * .pi) * 100))
            guard let endPoint = self.intersectionOfCircleAndLine(C: (centerCircle.x, centerCircle.y), radius: radius, D: (point.x, point.y), angle: angle - Double.pi, defaultPoint: defaultBottomPosition) else { return }
            print(endPoint)
            print("angle\(angle)")
            self.drawCircle(endAngle: angle, point: endPoint)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isDragging = false
        print("ntmlog isDragging\(false)")
    }
    
    func resetView() {
        self.centerCircle = CGPoint(x: self.view.frame.midX, y: self.view.frame.midY)
        self.setPercent(0)
        self.drawCircle(point: defaultPosition)
    }
    
    func setPercent(_ percent: Int) {
        self.radius1 = CGFloat(percent) * radius / 100
        self.percentView.frame = CGRect(origin: .zero, size: CGSize(width: radius1 * 2, height: radius1 * 2))
        self.percentView.center = self.percentLabel.center
        self.percentView.layer.cornerRadius = radius1
        self.percentLabel.text = "\(percent)%"
    }
}

extension ViewController {
    func checkIsOnRightPart(_ point: CGPoint) -> Bool {
        if point.x >= self.centerCircle.x {
            return true
        }
        return false
    }
    
    func checkIsTopPart(_ point: CGPoint) -> Bool {
        if point.y <= self.centerCircle.y {
            return true
        }
        return false
    }
    
    func calculateAngleBetweenLines(A: (Double, Double), B: (Double, Double), C: (Double, Double)) -> Double {
        let vectorAB = (B.0 - A.0, B.1 - A.1)
        let vectorAC = (C.0 - A.0, C.1 - A.1)

        let dotProduct = vectorAB.0 * vectorAC.0 + vectorAB.1 * vectorAC.1

        let magnitudeAB = sqrt(vectorAB.0 * vectorAB.0 + vectorAB.1 * vectorAB.1)
        let magnitudeAC = sqrt(vectorAC.0 * vectorAC.0 + vectorAC.1 * vectorAC.1)

        let cosAngle = dotProduct / (magnitudeAB * magnitudeAC)

        let angleRad = acos(cosAngle)
        
        return angleRad
    }
    
    func intersectionOfCircleAndLine(C: (Double, Double), radius: Double, D: (Double, Double), angle: Double, defaultPoint: CGPoint) -> CGPoint? {
        let (x2, y2) = C
        let (x3, y3) = D

        let m = (y2 - y3) / (x2 - x3)
        let c = y2 - x2 * m
        
        let a = 1 + m * m
        let b = 2 * (m * c - m * y2 - x2)
        let cc = y2 * y2 - radius * radius + x2 * x2 - 2 * c * y2 + c * c
        
        let discriminant = b * b - 4 * a * cc
        
        if discriminant < 0 {
            return nil
        }
        
        let x1 = (-b + sqrt(discriminant)) / (2 * a)
        let x22 = (-b - sqrt(discriminant)) / (2 * a)
        
        let y1 = m * x1 + c
        let y22 = m * x22 + c
         
        let angle1 = calculateAngleBetweenLines(A: (centerCircle.x, centerCircle.y), B: (defaultPoint.x, defaultPoint.y), C: (x1, y1))
        let angle2 = calculateAngleBetweenLines(A: (centerCircle.x, centerCircle.y), B: (defaultPoint.x, defaultPoint.y), C: (x22, y22))
        print("ntmlog\(abs(angle1 - angle))    \(abs(angle2 - angle))")
        if abs(angle1 - angle) > abs(angle2 - angle) {
            return CGPoint(x: x22, y: y22)
        }
        return CGPoint(x: x1, y: y1)
    }
}

