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
    //    @Published var id: UUID?
    @Published var name: String = ""
    @Published var author: String = ""
    @Published var tags: [Tag] = []
    @Published var image: UIImage = UIImage()
    //    @Published var isDone: Bool = false
    //    @Published var readMinutes: Int64 = 0
    //    @Published var createTime: Date = Date()
    //    @Published var doneTime: Date? = Date()
    //    @Published var rating: Int16 = 0
    
    var book:Book?
    
    func setBook(book:Book){
        //        if let book = book {
        //            self.id = book.id
        self.name = book.name
        if let author = book.author{
            self.author = author
        }
        if let tags = book.tags{
            self.tags = tags.split(separator: ",").map { Tag(name: String($0)) }
        }
        
        self.image = UIImage(data: book.image) ?? UIImage()
        //            self.isDone = book.isDone
        //            self.readMinutes = book.readMinutes
        //            self.createTime = book.createTime
        //            self.doneTime = book.doneTime
        //            self.rating = book.rating
        
        //            if let imageData =  book.image{
        //                self.image = UIImage(data: imageData)!
        //            }
        //            self.image = UIImage()
        //            self.doneTime = Date()
        //        }
        
        self.book = book
    }
    
    func clean(){
        self.book = nil
        //        self.id = nil
        self.name = ""
        self.author = ""
        self.tags = []
        self.image = UIImage(named: "camera")!
    }
}


struct Tag:Identifiable{
    let name:String
    var id:String{name}
}
