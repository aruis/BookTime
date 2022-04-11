//
//  BarView.swift
//  BookTime
//
//  Created by Liu Rui on 2022/4/11.
//

import SwiftUI



struct BarView: View {
    
    var data: ChartData
    
    var body: some View {
        HStack{
            ForEach(0 ... data.points.count,id: \.self){index in
                Text(data.points[index].0)
            }
        }
    }
}

struct BarView_Previews: PreviewProvider {
//    let data = ChartData(values: [("2021-01-01",10)])
    static var previews: some View {
        BarView(data: ChartData(values: [("2021-01-01",10)]))
    }
}
