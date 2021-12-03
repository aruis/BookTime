//
//  BookViewModel.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import Foundation
import Combine
import UIKit

class BookViewModel: ObservableObject{
    @Published var name: String = ""
    @Published var author: String = ""
    @Published var image: UIImage = UIImage()
    @Published var isDone: Bool = false
    @Published var readMinutes: Int64 = 0
    @Published var createTime: Date = Date()
    @Published var doneTime: Date? = Date()
    @Published var rating: Int16 = 0
    
    init(book:Book? = nil){
        if let book = book {
            self.name = book.name
            if let author = book.author{
                self.author = author
            }
            
            self.image = UIImage(data: book.image) ?? UIImage()
            self.isDone = book.isDone
            self.readMinutes = book.readMinutes
            self.createTime = book.createTime
            self.doneTime = book.doneTime
            self.rating = book.rating
            
//            if let imageData =  book.image{
                //                self.image = UIImage(data: imageData)!
//            }
            //            self.image = UIImage()
            //            self.doneTime = Date()
        }
    }
}
