//
//  Icon.swift
//  BookTime
//
//  Created by 牧云踏歌 on 2023/2/18.
//

import SwiftUI

struct Icon: View {
    
    let aspectRatio  = 8.0
    let bgColor = Color(red:2,green: 5,blue: 22)
    let paperColor = Color.white
    let spineColor = Color(red: 250, green: 144, blue: 63)
    let coverColor = Color(red: 207, green: 34, blue: 7)
    
    @Binding var iconSize:Double
    @Binding var deltaAngle:Double
    
    //    public init(iconSize:Double,deltaAngle:Double){
    //        self.iconSize = iconSize
    //        self.delta = deltaAngle
    //    }
    
    var hourAngle:Double {
        return 90.0 + deltaAngle * 10
    }
    
    var minAngle:Double {
        return -20 + deltaAngle
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            let size = geometry.size
            ZStack{
                Pie(startAngle: Angle(degrees: minAngle), endAngle: Angle(degrees: hourAngle), clockwise: false)
                    .fill(coverColor)
                    .frame(width: iconSize)
                
                RoundedRectangle(cornerRadius: iconSize/aspectRatio/2)
                    .fill(spineColor)
                    .frame(width: iconSize,height: iconSize/aspectRatio)
                    .position(x: size.width/2 + iconSize/2 - iconSize/aspectRatio/2,y: size.height/2)
                    .rotationEffect(Angle(degrees: hourAngle))
                
                RoundedRectangle(cornerRadius: iconSize/aspectRatio/2)
                    .fill(paperColor)
                    .frame(width: iconSize,height: iconSize/aspectRatio)
                    .position(x: size.width/2 + iconSize/2 - iconSize/aspectRatio/2,y: size.height/2)
                    .rotationEffect(Angle(degrees: minAngle))
                
            }
            
        }
        .frame(width: iconSize,height: iconSize)
        .background(bgColor)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.systemGray3), lineWidth: 1)
        )
        
    }
    
    
}

struct Pie: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(startAngle.degrees, endAngle.degrees)
        }
        set {
            self.startAngle = Angle(degrees: newValue.first)
            self.endAngle =  Angle(degrees: newValue.second)
        }
    }
    
    
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        )
        var path = Path()
        path.move(to: center)
        path.addLine(to: start)
        path.addArc(
            center: center,
            radius: radius*2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: (endAngle - startAngle) < Angle(degrees: 0)
        )
        path.addLine(to: center)
        return path
    }
}

struct Icon_Previews: PreviewProvider {
    static var previews: some View {
        Icon(iconSize: .constant(120),deltaAngle:.constant(0.0))
    }
}
