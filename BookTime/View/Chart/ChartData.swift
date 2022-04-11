//
//  ChartData.swift
//  BookTime
//
//  Created by Liu Rui on 2022/4/11.
//

import Foundation

public class ChartData: ObservableObject, Identifiable {
    @Published var points: [(String,Double)]
    
    public init<N: BinaryFloatingPoint>(values:[(String,N)]){
        self.points = values.map{($0.0, Double($0.1))}        
    }
}
