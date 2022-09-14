//
//  BookCardExport.swift
//  BookTime
//
//  Created by Liu Rui on 2022/9/14.
//

import SwiftUI

struct BookCardExport: View {
    
    var book: Book
    
    var body: some View {
        ZStack{
            Image(uiImage: UIImage(data: book.image) ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(height:400)
        }
        .padding(2)
        .overlay(alignment: .bottom, content: {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 80)
                .foregroundColor(.black)
                .opacity(0.80)
                .overlay(
                    HStack{
                        VStack(spacing:8){
                            HStack(spacing:10){
                                ForEach(0...4,id: \.self) {index in
                                    Image(systemName: book.rating > index ? "star.fill" : "star")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AccentColor"))
                                }
                            }
                            
                            if ( Locale.current.languageCode == "zh"){
                                HStack(spacing:0){
                                    Text("阅读")
                                    Text("**\(book.readDays)**")
                                    Text("天，共计")
                                    //                                Text("")
                                    Text("**\(book.readMinutes)**分钟")
                                }
                                .frame(maxWidth:.infinity)
                                .font(.footnote)
                                .foregroundColor(.white)
                            }else{
                                HStack(spacing:0){
                                    Text("Read ")
                                    Text("**\(book.readMinutes)**")
                                    Text(" minutes in ")
                                    //                                Text("")
                                    Text("**\(book.readDays)**")
                                    Text(" days")
                                }
                                .frame(maxWidth:.infinity)
                                .font(.caption)
                                .foregroundColor(.white)
                                
                            }
                            
                            if let doneTime = book.doneTime , let firstReadTime = book.firstReadTime{
                                HStack(spacing:2){
                                    Text(firstReadTime.format("yyyy-MM-dd"))
                                    Text("~")
                                    Text(doneTime.format("yyyy-MM-dd"))
                                }
                                .font(.caption2)
                                .foregroundColor(.white)
                                
                                //                            Text("于\(doneTime.format("yyyy-MM-dd"))读完")
                            }
                            
                        }
                        
                        Spacer()
                        
                        Image("qr")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60,height: 60)
                        
                    }
                        .padding(15)
                )
        })
        .overlay(
            Rectangle()
                .stroke(lineWidth: 3)
                .foregroundColor(.black)
        )
        .ignoresSafeArea()

    }
}

struct BookCardExport_Previews: PreviewProvider {
    static var previews: some View {
//        let book = Book(entity: <#T##NSEntityDescription#>, insertInto: <#T##NSManagedObjectContext?#>)
//        BookCardExport(book:)
        Text("")
    }
}
