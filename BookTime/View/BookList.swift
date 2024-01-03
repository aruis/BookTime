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
    @EnvironmentObject var appData: AppData
    
    @AppStorage("todayReadMin") var todayReadMin = 0
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    let ctrl = BookPersistenceController.shared
    let generator = UINotificationFeedbackGenerator()
    
    let keyStore = NSUbiquitousKeyValueStore()
    
    
    @SectionedFetchRequest(
        sectionIdentifier: \.status,
        sortDescriptors: [
            SortDescriptor(\Book.status, order: .forward),
            //            SortDescriptor(\Book.lastReadTime, order: .forward),
            SortDescriptor(\Book.createTime, order: .reverse)
        ])
    private var booksGroup: SectionedFetchResults<Int16, Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \ReadLog.day, ascending: true)
    ],predicate:NSPredicate(format: "readMinutes > 0"))
    var logs: FetchedResults<ReadLog>
    
    
    @Environment(\.managedObjectContext) var context
    
    @State var showNewBook = false
    @State private var showingAlert = false
    @State private var searchText = ""
    @State private var showAlert:Bool = false
    @State private var wantDelete:Book? = nil
    //    @State private var tags:[Tag] = []
    @State private var selectTag:Tag? = nil
    
    @State private var selectBook:Book?
    
    @StateObject private var bookViewModel: BookViewModel = BookViewModel()
    
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    
    @ViewBuilder
    func itemInList(book:Book) -> some View{
        ZStack(alignment: .leading){
            NavigationLink(value: book){
                EmptyView()
            }
            .opacity(0)
            
            BookListItem(book: book)
            
        }
        .contextMenu {
            
            Button(action: {
                self.bookViewModel.setBook(book: book)
                self.showNewBook = true
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
        .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
            Button(action: {
                self.bookViewModel.setBook(book: book)
                self.showNewBook = true
                //                                self.showError.toggle()
            }) {
                Image(systemName: "pencil.circle")
            }
            .tint(.blue)
            
        })
        .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
            Button(role: .destructive, action: {
                self.showAlert = true
                wantDelete = book
                generator.notificationOccurred(.warning)
                
            })  {
                Image(systemName: "trash")
            }
            
            
            Button {
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
                
            }label: {
                Image(systemName: "archivebox")
            }
            .tint(.orange)
            
        })
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
        
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectBook){
                    ForEach(booksGroup) { section in
                        Section(header: Text(getSectionHeader(iStatus: section.id  ) + "·\(section.count)" ).monospacedDigit() ) {
                            ForEach(section) { book in
                                itemInList(book:book)
                            }
                            
                        }
                    }
                
            }
            //                    .navigationDestination(for: Book.self, destination: {book in
            //                        BookCard(book:book)
            //                    })
            .navigationDestination(isPresented: $showNewBook){
                NewBook(bookViewModel:bookViewModel)
                    .onDisappear{
                        initTags()
                    }
            }
            
            //                .listStyle(.grouped)
            //                .listStyle(.sidebar)
            .navigationTitle("My Bookshelf")
            .confirmationDialog("Cancel", isPresented: $showAlert, actions: {
                //                    index
                Button("Delete this book (unrecoverable)", role: .destructive) {
                    delete(book: wantDelete)
                    initTags()
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
                
                booksGroup.nsPredicate = predicate
            }
            .overlay{
                if  booksGroup.count == 0 && searchText.isEmpty  {
                    AddBookView()
                        .onTapGesture {
                            bookViewModel.clean()
                            self.showNewBook = true
                        }
                }
            }
            .toolbar{                
                ToolbarItem(placement: .cancellationAction){
                    if !appData.tags.isEmpty{
                        Menu {
                            
                            ForEach(appData.tags){tag in
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
                
                ToolbarItem(placement: .primaryAction){
                    Button(action: {
                        bookViewModel.clean()
                        self.showNewBook = true
                    }){
                        Image(systemName: "plus")
                    }
                }
            }            
        } detail:{
            if let selectBook {
                BookCard(book:selectBook)
                    .id(selectBook.id)
            } else {
                Button(action: {
                    columnVisibility = .doubleColumn
                }) {
                    Text("Please select a book.")
                        .bold()
                        .font(.largeTitle)
                }
                .tint(.accentColor)
                .buttonStyle(.bordered)
                //                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                
            }
            
            
            
            //                        .foregroundColor(.white)
            //                        .padding(Edge.Set.vertical,8)
            //                        .padding(Edge.Set.horizontal,14)
            //
            //                        .background(Color.accentColor)
            //                        .clipShape(
            //                            RoundedRectangle(cornerRadius: 25, style: .continuous)
            //                        )
            
            
            //                .clipShape(RoundedRectangle(cornerRadius: 25, style: .cornerSize))
            
            //                    .background(Color(UIColor(<#T##SwiftUI.Color#>)))
            //
        }
        .task(priority: .low) {
            initTags()
            //                isDone2status()
            
            
            var logInYear =  [Int](repeating: 0, count: 366)
            
            let now = Date()
            
            todayReadMin = 0
            
            for log:ReadLog in logs{
                if(now.isSameYear(log.day) && log.readMinutes > logInYear[log.day.dayOfYear-1]){
                    logInYear[log.day.dayOfYear-1] = log.readMinutes
                }
                if(Calendar.current.isDateInToday(log.day) && log.readMinutes > todayReadMin){
                    todayReadMin = log.readMinutes
                }
            }
            
            keyStore.set(todayReadMin, forKey: "todayReadMin")
            keyStore.set(logInYear, forKey: "logInYear")
            keyStore.synchronize()
            
            WidgetCenter.shared.reloadAllTimelines()
            
        }
        
        
        
        
        
    }
    
    func initTags(){
        appData.tags.removeAll()
        
        booksGroup.forEach{
            $0.forEach{book in
                if let tagString = book.tags ,!tagString.isEmpty {
                    tagString.split(separator: ",").forEach{
                        let _tag = Tag(name: String($0))
                        if(appData.tags.firstIndex(where: { tag in
                            tag.name == _tag.name
                        }) == nil){
                            appData.tags.append(_tag)
                        }
                    }
                }
            }
            
        }
        
        //        booksAll.forEach()
        
    }
    
    //    func isDone2status(){
    //
    //
    //        var change = false
    //
    //        booksAll.forEach{book in
    //            if book.status != BookStatus.archive.rawValue{
    //                change = true
    //                book.status  = book.isDone ? BookStatus.readed.rawValue : BookStatus.reading.rawValue
    //            }
    //
    //        }
    //
    //        if change {
    //            DispatchQueue.main.async {
    //                do{
    //                    try context.save()
    //                }catch{
    //                    print(error)
    //                }
    //            }
    //        }
    //    }
    
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
        
        Image(systemName: "plus.circle")
            .font(.system(size: 70))
            .foregroundColor(.accentColor)
            .overlay(alignment: .bottom){
                Text("Tap here to add a book")
                    .frame(width: 300)
                    .font(.title)
                    .offset(y:60)
            }        
        
        
    }
}
