//
//  BookList.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import CoreData
import CloudKit

struct SelectedSort: Equatable {
    var by = 0
    var order = 0
    var index: Int { by + order }
}

struct BookList: View {
    let generator = UINotificationFeedbackGenerator()
    
    // TODO 排序问题
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.isDone, ascending: true),
        NSSortDescriptor(keyPath: \Book.createTime, ascending: false)
    ])
    var books: FetchedResults<Book>
    
    @SectionedFetchRequest(
        sectionIdentifier: \.isDone,
        sortDescriptors: [SortDescriptor(\Book.isDone, order: .forward),SortDescriptor(\Book.createTime, order: .reverse)])
    private var quakes: SectionedFetchResults<Bool, Book>
    
    //    @State private var selectedSort = SelectedSort()
    
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
                    Text("点此添加您的第一本书")
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
                                    Text("修改信息")
                                    Image(systemName: "pencil.circle")
                                }
                            }
                            
                            Button(action: {
                                self.showAlert = true
                                wantDelete = book
                                generator.notificationOccurred(.warning)
                            }){
                                HStack{
                                    Text("删除此书")
                                    Image(systemName: "trash")
                                }.foregroundColor(.red)
                                
                            }
                            
                        }
                        
                        .listRowSeparator(.hidden)
                        
                    }
                    
                }
                .listStyle(.plain)
                //                .listStyle(.sidebar)
                .navigationTitle("我的书架")
                .confirmationDialog("", isPresented: $showAlert, actions: {
                    //                    index
                    Button("删除此书（不可恢复）", role: .destructive) {
                        delete(book: wantDelete)
                    }
                    Button("取消", role: .cancel) {
                        self.showAlert = false
                    }
                })
                
                .navigationBarTitleDisplayMode(.automatic)
                .searchable(text: $searchText,  prompt: "按书名搜索" )
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
        .task {
//            await fetchBooksFromICloud()
//            
//            for book:Book in books{
//                saveBookToICloud(book: book)
//            }
            
        }
        .sheet(isPresented: $showNewBook){
            NewBook(bookViewModel:bookViewModel)
        }
    }
    
    func  fetchBooksFromICloud () async{
        let cloudContainer = CKContainer.default()
        let privateDB = cloudContainer.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Book", predicate: predicate)

        do {
            let results = try await privateDB.records(matching: query)
            
            for record in results.matchResults {
                let rec =  try record.1.get()
                print(rec)
            }

            
            // Process the records

        } catch {
            // Handle the error
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
 
    func saveBookToICloud(book:Book){
        let record = CKRecord(recordType: "Book")
        record.setValue(book.id.uuidString, forKey: "id")
        record.setValue(book.name, forKey: "name")
        record.setValue(book.author, forKey: "author")
        record.setValue(book.isDone, forKey: "isDone")
        record.setValue(book.readMinutes, forKey: "readMinutes")
        record.setValue(book.createTime, forKey: "createTime")
        record.setValue(book.firstReadTime, forKey: "firstReadTime")
        record.setValue(book.lastReadTime, forKey: "lastReadTime")
        record.setValue(book.doneTime, forKey: "doneTime")
        record.setValue(book.rating, forKey: "rating")
        record.setValue(book.readDays, forKey: "readDays")
        
        
        let imageFilePath = NSTemporaryDirectory() + book.name
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        try? book.image.write(to: imageFileURL)
                
        let imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "image")

        // Get the Public iCloud Database
        let publicDatabase = CKContainer.default().privateCloudDatabase

        // Save the record to iCloud
        publicDatabase.save(record, completionHandler: { (record, error) -> Void  in

            print("uploaded")
            
            if error != nil {
                print(error.debugDescription)
            }

            // Remove temp file
            try? FileManager.default.removeItem(at: imageFileURL)
        })

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
