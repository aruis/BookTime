//
//  BookListItem.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI

struct BookListItem: View {
    @ObservedObject var book: Book
    
    var body: some View {
        
        HStack(alignment: .top) {
            if let imageData = book.image{
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
//                    .cornerRadius(12)
                    .overlay(
                        Rectangle()
                            .stroke(Color("image.border"), lineWidth: 1)
                    )
                    .shadow(color: Color( "image.border"), radius: 5,x:2,y:2)
//                    .shadow(radius: 10)
            }
            
            
            VStack(alignment: .leading,spacing: 6) {
                Text(book.name)
                    .font(.system(.title3, design: .rounded))
                
                if let author = book.author {
                    if( author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false){
                        Text(author)
                            .font(.system(.body))
                            .foregroundColor(.gray)
                    }
                }
                
                                
                HStack(alignment: .bottom,spacing: 6) {
                    if book.isDone{
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(.subheadline,design: .rounded))
                            .foregroundColor(.green)
                    }else{
                        Image(systemName: "deskclock")
                            .font(.system(.subheadline,design: .rounded))
                    }
                    
                    Text(book.readMinutes.asString())
                        .font(.system (.subheadline,design: .rounded))
                }
                //                        .foregroundColor(.gray)
            }
            .padding(.leading,8)
            .padding(.trailing,8)
            .padding(.top,10)
            
        }
        
    }
}

struct BookListItem_Previews: PreviewProvider {
    static var previews: some View {
        BookListItem(book: (BookPersistenceController.testData?.first)!)
        //            .previewLayout(.sizeThatFits)
        
        BookListItem(book: (BookPersistenceController.testData?.first)!)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        
    }
}
