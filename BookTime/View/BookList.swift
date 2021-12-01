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
    
    var body: some View {
        NavigationView {
            List{
                ForEach(books.indices,id:\.self){index in
                    NavigationLink(
                        destination: BookCard(book: books[index])
                            
//                            .padding(.top,10)
                    ){
                        
                        BookListItem(book: books[index])
                            .swipeActions(edge: .leading, allowsFullSwipe: false, content: {
                                Button{
                                    doneBook(book: books[index])
                                }label: {
                                    if books[index].isDone{
                                        Label("没读完",systemImage: "exclamationmark.arrow.circlepath" )
                                    }else{
                                        Label("已读完",systemImage: "checkmark.circle" )
                                    }
                                    
                                }
                                .tint(books[index].isDone ? Color("xwarning") : .green )
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                                Button{
                                    showingAlert = true
                                }label: {
                                    Label( "删除", systemImage:  "trash")
                                }
                                .tint(Color("warning"))
                            })
                            .alert(isPresented: $showingAlert){
                                Alert(title: Text("确定删除吗？"), message: Text("删除后不可恢复哦"),
                                      primaryButton: .destructive(Text("删除"),action: {
                                    deleteBook(book: books[index])
                                }),
                                      secondaryButton: .cancel(Text("取消")))
                            }}
                    
                    
                }
                
                
                
                            .listRowSeparator(.hidden)
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
    
    private func doneBook(book:Book){
        book.isDone.toggle()
        book.doneTime = Date()
        //        context.delete(book)
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
