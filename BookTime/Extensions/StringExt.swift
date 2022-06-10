//
//  StringExt.swift
//  BookTime
//
//  Created by Liu Rui on 2022/6/6.
//

import Foundation

extension String {
    subscript(digitIndex: Int) -> String {
        if digitIndex < 0 || digitIndex >= self.count{
            return ""
        }
        
        let arr = self.map{String($0)}
        return arr[digitIndex]
    }
}
