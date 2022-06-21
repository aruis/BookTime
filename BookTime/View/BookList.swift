//
//  BookList.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import CoreData
import CloudKit
import WidgetKit

struct BookList: View {
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    let ctrl = BookPersistenceController.shared
    let generator = UINotificationFeedbackGenerator()
    
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.status, ascending: true),
        //        NSSortDescriptor(keyPath: \Book.lastReadTime, ascending: false),
        NSSortDescriptor(keyPath: \Book.createTime, ascending: false)
    ])
    var books: FetchedResults<Book>
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.status, ascending: true),
        //        NSSortDescriptor(keyPath: \Book.lastReadTime, ascending: false),
        NSSortDescriptor(keyPath: \Book.createTime, ascending: false)
    ])
    var booksAll: FetchedResults<Book>
    
    @SectionedFetchRequest(
        sectionIdentifier: \.status,
        sortDescriptors: [
            SortDescriptor(\Book.status, order: .forward),
            //            SortDescriptor(\Book.lastReadTime, order: .forward),
            SortDescriptor(\Book.createTime, order: .reverse)
        ])
    private var booksGroup: SectionedFetchResults<Int16, Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[])
    var logs: FetchedResults<ReadLog>
    
    @Environment(\.managedObjectContext) var context
    
    @State var showNewBook = false
    @State private var showingAlert = false
    @State private var searchText = ""
    @State private var showAlert:Bool = false
    @State private var wantDelete:Book? = nil
    @State private var tags:[Tag] = []
    @State private var selectTag:Tag? = nil
    
    @StateObject private var bookViewModel: BookViewModel = BookViewModel()
    
    
    @ViewBuilder
    func itemInList(book:Book) -> some View{
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
                    Text("Modify the Book")
                    Image(systemName: "pencil.circle")
                }
            }
            
            Button(role: .cancel, action: {
                if  book.status != BookStatus.archive.rawValue {
                    book.status = BookStatus.archive.rawValue
                }else{
                    book.status = BookStatus.reading.rawValue
                }
                
                DispatchQueue.main.async {
                    do{
                        try context.save()
                    }catch{
                        print(error)
                    }
                }
                
                generator.notificationOccurred(.warning)
                
            })  {
                HStack{
                    Text(book.status != BookStatus.archive.rawValue ? "Archive the Book" : "Unarchive the Book")
                    Image(systemName: "archivebox")
                }
            }
            
            Button(role: .destructive, action: {
                self.showAlert = true
                wantDelete = book
                generator.notificationOccurred(.warning)
                
            })  {
                HStack{
                    Text("Delete the Book")
                    Image(systemName: "trash")
                }
                
            }
        }
        .listRowSeparator(.hidden)
    }
    
    
    func getSectionHeader(iStatus:Int16) -> String{
        let status = BookStatus(rawValue: iStatus)
        
        if let status = status {
            switch status {
            case .reading:
                return String(localized: "Unfinished")
            case .readed:
                return String(localized: "Finished")
            case .archive:
                return String(localized: "Archive")
            }
        }else{
            return String(localized: "Unfinished")
        }
        
    }
    
    var body: some View {
        NavigationView {
            if UIDevice.current.userInterfaceIdiom == .phone && booksAll.count == 0 {
                AddBookView()
                    .onTapGesture {
                        bookViewModel.clean()
                        self.showNewBook = true
                    }
            } else {
                List{
                    if searchText.isEmpty {
                        ForEach(booksGroup) { section in
                            Section(header: Text(getSectionHeader(iStatus: section.id  ) + "·\(section.count)" ).monospacedDigit() ) {
                                ForEach(section) { book in
                                    itemInList(book:book)
                                }
                                
                            }
                        }
                        
                        
                    }else{
                        ForEach(books) { book in
                            itemInList(book:book)
                        }
                        
                    }
                    
                }
                
                //                .listStyle(.automatic)
                .listStyle(.sidebar)
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
                .toolbar{
                    
                    ToolbarItem(placement: .navigation){
                        if !tags.isEmpty{
                            Menu {
                                
                                ForEach(tags){tag in
                                    Button( action: {
                                        selectTag = tag
                                        
                                        let predicate = NSPredicate(format: "tags CONTAINS[c] %@ ", tag.name+",")
                                        booksGroup.nsPredicate = predicate
                                        
                                    },label: {
                                        Label(tag.name,systemImage: selectTag?.name == tag.name ?  "checkmark" : "")
                                    })
                                }
                                
                                Button(action: {
                                    selectTag = nil
                                    
                                    let predicate = NSPredicate(value: true)
                                    booksGroup.nsPredicate = predicate
                                    
                                }, label: {
                                    Label("-",systemImage: selectTag == nil ?  "checkmark" : "")
                                })
                                
                                
                            } label:{
                                Label(selectTag?.name ?? "",systemImage: selectTag != nil ? "tag.fill" :"tag")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                    
                    
                }
                
                
            }
            
            AddBookView()
                .onTapGesture {
                    bookViewModel.clean()
                    self.showNewBook = true
                }
        }
        .autoNav()
        .sheet(isPresented: $showNewBook){
            NewBook(bookViewModel:bookViewModel,tags: tags)
                .onDisappear(perform: {
                    initTags()
                })
        }
        .task {
            initTags()
            isDone2status()
            
            let readMinToday =  BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes
            
            UserDefaults(suiteName:"group.com.aruistar.BookTime")!.set(readMinToday, forKey: "todayReadMin")
            UserDefaults(suiteName:"group.com.aruistar.BookTime")!.set(targetMinPerday, forKey: "targetMinPerday")
            WidgetCenter.shared.reloadAllTimelines()
            
        }
        
    }
    
    func initTags(){
        tags.removeAll()
        booksAll.forEach({book in
            if let tagString = book.tags ,!tagString.isEmpty {
                tagString.split(separator: ",").forEach{
                    let _tag = Tag(name: String($0))
                    if(tags.firstIndex(where: { tag in
                        tag.name == _tag.name
                    }) == nil){
                        tags.append(_tag)
                    }
                }
            }
        })
        
    }
    
    func isDone2status(){
        
        
        booksAll.forEach{book in
            if book.status != BookStatus.archive.rawValue{
                book.status  = book.isDone ? BookStatus.readed.rawValue : BookStatus.reading.rawValue
            }
            
        }
        
        
        DispatchQueue.main.async {
            do{
                try context.save()
            }catch{
                print(error)
            }
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

struct AutoNav: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            content
                .navigationViewStyle(.stack)
        }else{
            content
        }
        
    }
}

extension View {
    func autoNav() -> some View {
        modifier(AutoNav())
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

struct AddBookView: View {
    @State private var handMove = false
    
    var body: some View {
        VStack (spacing: 20){
            Image(systemName: "plus.circle")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
                .overlay(
                    Image(systemName: "hand.point.up.left")
                        .font(.system(size: 100))
                        .foregroundColor(.gray.opacity(handMove ? 0.6:0.85))
                        .offset(x: handMove ? 150 : 50,y: handMove ? 150 : 50)
                )
                .onAppear(perform: {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)){
                        handMove.toggle()
                    }
                })
            
            Text("Tap here to add a book")
                .font(.title)
        }
    }
}
