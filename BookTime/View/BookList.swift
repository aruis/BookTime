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
    @State private var searchDebounceTask: Task<Void, Never>? = nil
    @State private var tagRefreshTask: Task<Void, Never>? = nil
    @State private var readSummaryTask: Task<Void, Never>? = nil
    
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
                        scheduleTagRefresh(immediate: true)
                    }
            }
            
            //                .listStyle(.grouped)
            //                .listStyle(.sidebar)
            .navigationTitle("My Bookshelf")
            .confirmationDialog("Cancel", isPresented: $showAlert, actions: {
                //                    index
                Button("Delete this book (unrecoverable)", role: .destructive) {
                    delete(book: wantDelete)
                    scheduleTagRefresh(immediate: true)
                }
                Button("Cancel", role: .cancel) {
                    self.showAlert = false
                }
            })
            .navigationBarTitleDisplayMode(.automatic)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by book title" )
            .onChange(of: searchText,{
                searchDebounceTask?.cancel()
                let currentText = searchText
                
                searchDebounceTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if Task.isCancelled { return }
                    
                    let predicate = currentText.isEmpty
                    ? NSPredicate(value: true)
                    : NSPredicate(format: "name CONTAINS[c] %@ ", currentText)
                    
                    await MainActor.run {
                        booksGroup.nsPredicate = predicate
                    }
                }
            })
            .overlay{
                if  booksGroup.count == 0 && searchText.isEmpty  {
                    
                    Button(action: {
                        bookViewModel.clean()
                        self.showNewBook = true
                    }, label: {
                        Label("Tap here to add a book", systemImage: "plus.circle")
                    })
                    .font(.title)
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
                                    if selectTag?.name == tag.name {
                                        Label(tag.name,systemImage: "checkmark")
                                    }else{
                                        Text(tag.name )
                                    }
                                    
                                })
                            }
                            
                            Button(action: {
                                selectTag = nil
                                
                                Task{                                    
                                    booksGroup.nsPredicate = NSPredicate(value: true)
                                }
                                
                                
                                
                            }, label: {
                                if selectTag == nil {
                                    Label("-",systemImage: "checkmark")
                                }else{
                                    Text("-")
                                }
                                
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
            scheduleTagRefresh()
            scheduleReadSummaryRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)) { notification in
            if hasReadLogChanges(notification.userInfo) {
                scheduleReadSummaryRefresh()
            }
            
            if hasBookChanges(notification.userInfo) {
                scheduleTagRefresh(immediate: true)
            }
        }
        .onDisappear {
            searchDebounceTask?.cancel()
            tagRefreshTask?.cancel()
            readSummaryTask?.cancel()
        }
        
        
        
        
        
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
    
    private func hasReadLogChanges(_ userInfo: [AnyHashable: Any]?) -> Bool {
        guard let userInfo else { return false }
        
        let keys: [String] = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]
        for key in keys {
            if let objects = userInfo[key] as? Set<NSManagedObject>,
               objects.contains(where: { $0.entity.name == "ReadLog" }) {
                return true
            }
        }
        
        return false
    }
    
    private func hasBookChanges(_ userInfo: [AnyHashable: Any]?) -> Bool {
        guard let userInfo else { return false }
        
        let keys: [String] = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]
        for key in keys {
            if let objects = userInfo[key] as? Set<NSManagedObject>,
               objects.contains(where: { $0.entity.name == "Book" }) {
                return true
            }
        }
        
        return false
    }
    
    private func scheduleTagRefresh(immediate: Bool = false) {
        tagRefreshTask?.cancel()
        tagRefreshTask = Task(priority: .utility) {
            if !immediate {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            
            guard !Task.isCancelled else { return }
            let tags = await ctrl.fetchTags()
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                appData.tags = tags
            }
        }
    }
    
    private func scheduleReadSummaryRefresh() {
        readSummaryTask?.cancel()
        readSummaryTask = Task(priority: .utility) {
            let summary = await ctrl.fetchReadSummary()
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                persistReadSummaryIfNeeded(summary)
            }
        }
    }
    
    private func persistReadSummaryIfNeeded(_ summary: BookReadSummary) {
        let storedLogInYear = keyStore.array(forKey: "logInYear") as? [Int] ?? []
        let hasTodayChanged = todayReadMin != summary.todayReadMin
        let hasYearLogChanged = storedLogInYear != summary.logInYear
        
        guard hasTodayChanged || hasYearLogChanged else { return }
        
        todayReadMin = summary.todayReadMin
        keyStore.set(summary.todayReadMin, forKey: "todayReadMin")
        keyStore.set(summary.logInYear, forKey: "logInYear")
        keyStore.synchronize()
        
        WidgetCenter.shared.reloadAllTimelines()
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
