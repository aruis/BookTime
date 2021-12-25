//
//  BookList.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import CoreData
import CloudKit


struct BookList: View {
        
    let ctrl = BookPersistenceController.shared
    let generator = UINotificationFeedbackGenerator()
    
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.isDone, ascending: true),
        NSSortDescriptor(keyPath: \Book.createTime, ascending: false)
    ])
    var books: FetchedResults<Book>
    
    @SectionedFetchRequest(
        sectionIdentifier: \.isDone,
        sortDescriptors: [SortDescriptor(\Book.isDone, order: .forward),SortDescriptor(\Book.createTime, order: .reverse)])
    private var quakes: SectionedFetchResults<Bool, Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[])
    var logs: FetchedResults<ReadLog>
    
    @Environment(\.managedObjectContext) var context
    
    @State var showNewBook = false
    @State private var showingAlert = false
    @State private var searchText = ""
    @State private var showAlert:Bool = false
    
    @State private var wantDelete:Book? = nil
    
    @StateObject private var bookViewModel: BookViewModel = BookViewModel()
    
    var body: some View {
        NavigationView {
            if books.count == 0 {
                VStack (spacing: 10){
                    Image(systemName: "plus.circle").font(.largeTitle)
                        .foregroundColor(.accentColor)
                    Text("Tap here to add your first book")
                }.onTapGesture {
                    bookViewModel.clean()
                    self.showNewBook = true
                }
                
            } else {
                List{
//                    ForEach(quakes) { section in
//                        Section(header: Text((section.id ? "已读完" : "未读完") + "·\(section.count)" ).monospacedDigit() ) {
//
//                        }
//                    }
                    ForEach(books) { book in
                        ZStack(alignment: .leading){
                            NavigationLink(
                                destination: BookCard(book:book)
                            ){
                                EmptyView()
                            }.opacity(0)
                            
                            BookListItem(book: book)
                            
                        }
                        .contextMenu {
                            
                            Button(action: {
                                self.bookViewModel.setBook(book: book)
                                self.showNewBook = true
                                //                                self.showError.toggle()
                            }) {
                                HStack {
                                    Text("Modify the book")
                                    Image(systemName: "pencil.circle")
                                }
                            }
                            
                            Button(action: {
                                self.showAlert = true
                                wantDelete = book
                                generator.notificationOccurred(.warning)
                            }){
                                HStack{
                                    Text("Delete the book")
                                    Image(systemName: "trash")
                                }.foregroundColor(.red)
                                
                            }
                            
                        }
                        
                        .listRowSeparator(.hidden)
                        
                    }
                    
                }
                .listStyle(.plain)
                //                .listStyle(.sidebar)
                .navigationTitle("My Bookshelf")
                .confirmationDialog("Cancel", isPresented: $showAlert, actions: {
                    //                    index
                    Button("Delete this book (unrecoverable)", role: .destructive) {
                        delete(book: wantDelete)
                    }
                    Button("Cancel", role: .cancel) {
                        self.showAlert = false
                    }
                })
                .onAppear(perform: {
                    BookPersistenceController.shared.checkAndBuildTodayLog()
                })
                .navigationBarTitleDisplayMode(.automatic)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by book title" )
                .onChange(of: searchText){ searchText in
                    let predicate = searchText.isEmpty
                    ? NSPredicate(value: true)
                    : NSPredicate(format: "name CONTAINS[c] %@ ", searchText)
                    
                    books.nsPredicate = predicate
                }
                //                .toolbar(content: {
                //                    ToolbarItem(placement: .bottomBar){
                //                        if MyTool.checkAndBuildTodayLog(context: context).readMinutes > 0{
                //                            Text("今日阅读时长：\(MyTool.checkAndBuildTodayLog(context: context).readMinutes)分钟")
                //                        }else if(books.count>0){
                //                            Text("今天还没有开始阅读呦")
                //                        }else{
                //
                //                        }
                //
                //                    }
                //                })
                .toolbar{
                    Button(action: {
                        bookViewModel.clean()
                        self.showNewBook = true
                    }){
                        Image(systemName: "plus")
                    }
                    
                }
                
                
            }
            
            
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showNewBook){
            NewBook(bookViewModel:bookViewModel)
        }
       
    }
        
    
    func delete(book:Book?){
        if let book = book{
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
 
    func local2Cloud() async{
        await  ctrl.cleanCloud()
        
        for book in books{
            ctrl.saveBookInICloud(book: book)
        }
        
        for log in logs{
            ctrl.saveLogInICloud(log: log)
        }
        
        ctrl.tapLastBackuptime()

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
