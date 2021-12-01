//
//  BookList.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI

struct BookList: View {
    
    @FetchRequest(entity: Book.entity(), sortDescriptors: [])
    var books: FetchedResults<Book>
    
    @Environment(\.managedObjectContext) var context
    
    @State var showNewBook = false
    
    var body: some View {
        NavigationView {
            List{
                ForEach(books.indices,id:\.self){index in
                    BookListItem(book: books[index])
                        .swipeActions(edge: .leading, allowsFullSwipe: false, content: {
                            Button{
                                
                            }label: {
                                Label("已读完",systemImage: "checkmark.circle" )
                            }
                            .tint(.green)
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                            Button{
                                deleteBook(book: books[index])
                            }label: {
                                Label( "删除", systemImage:  "trash")
                                
                            }
                            .tint(Color("warning"))
                        })
                }
             
                
                //            .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("我的书架")
            .navigationBarTitleDisplayMode(.automatic)
            
            .toolbar{
                Button(action: {
                    self.showNewBook = true
                }){
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showNewBook){
                NewBook()
            }
        }
        
    }
    
    private func deleteBook(book:Book){
        context.delete(book)
        DispatchQueue.main.async {
            do{
                try context.save()
            }catch{
                print(error)
            }
        }
    }
}

struct BookList_Previews: PreviewProvider {
    static var previews: some View {
        BookList()
            .environment(\.managedObjectContext,BookPersistenceController.preview.container.viewContext)
        
        BookList()
            .environment(\.managedObjectContext,BookPersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
