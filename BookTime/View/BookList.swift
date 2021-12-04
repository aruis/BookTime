//
//  BookList.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI

struct BookList: View {
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.createTime, ascending: false)
    ])
    var books: FetchedResults<Book>
    
    @Environment(\.managedObjectContext) var context
    
    @State var showNewBook = false
    @State private var showingAlert = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List{
                ForEach(books.indices,id:\.self){index in
                    ZStack(alignment: .leading){
                        NavigationLink(
                            destination: BookCard(book: books[index])
                        ){
                            EmptyView()
                        }.opacity(0)
                        
                        BookListItem(book: books[index])
                        
                    }
                    .listRowSeparator(.hidden)
                }
            
            }
            .listStyle(.plain)
            .navigationTitle("我的书架")
            .navigationBarTitleDisplayMode(.automatic)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索一本书" )
            .onChange(of: searchText){ searchText in
                let predicate = searchText.isEmpty
                ? NSPredicate(value: true)
                : NSPredicate(format: "name CONTAINS[c] %@ ", searchText)
                
                books.nsPredicate = predicate
            }

            .toolbar{
                Button(action: {
                    self.showNewBook = true
                }){
                    Image(systemName: "plus")
                }
                
            }
         
            
        }
        .sheet(isPresented: $showNewBook){
            NewBook()
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
