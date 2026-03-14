//
//  BookListItem.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import CoreData

private final class BookCoverImageCache {
    static let shared = BookCoverImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 200
    }
    
    func image(for key: String) -> UIImage? {
        let nsKey = key as NSString
        return cache.object(forKey: nsKey)
    }
    
    func store(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

private final class BookCoverImageLoader {
    static let shared = BookCoverImageLoader()
    private var inFlightKeys = Set<String>()
    private let lock = NSLock()
    
    private init() {}
    
    func load(key: String, data: Data, completion: @escaping (UIImage?) -> Void) {
        if let image = BookCoverImageCache.shared.image(for: key) {
            completion(image)
            return
        }
        
        lock.lock()
        if inFlightKeys.contains(key) {
            lock.unlock()
            return
        }
        inFlightKeys.insert(key)
        lock.unlock()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let image = UIImage(data: data)
            
            if let image {
                BookCoverImageCache.shared.store(image, for: key)
            }
            
            DispatchQueue.main.async {
                self.lock.lock()
                self.inFlightKeys.remove(key)
                self.lock.unlock()
                completion(image)
            }
        }
    }
}

private final class BookThumbnailGenerator {
    static let shared = BookThumbnailGenerator()
    private var inFlightKeys = Set<String>()
    private let lock = NSLock()
    
    private init() {}
    
    func generateIfNeeded(key: String, sourceData: Data, completion: @escaping (Data?) -> Void) {
        lock.lock()
        if inFlightKeys.contains(key) {
            lock.unlock()
            return
        }
        inFlightKeys.insert(key)
        lock.unlock()
        
        DispatchQueue.global(qos: .utility).async {
            let thumbnailData = sourceData.makeThumbnailData()
            DispatchQueue.main.async {
                self.lock.lock()
                self.inFlightKeys.remove(key)
                self.lock.unlock()
                completion(thumbnailData)
            }
        }
    }
}

struct BookListItem: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var book: Book
    @State private var coverImage: UIImage?
    
    private var coverKey: String {
        let thumbnailCount = book.thumbnailImage?.count ?? 0
        return "\(book.objectID.uriRepresentation().absoluteString)-\(book.image.count)-\(thumbnailCount)"
    }
    
    var body: some View {
        
        HStack(alignment: .top) {
            cover
                .overlay(
                    Rectangle()
                        .stroke(Color("image.border"), lineWidth: 1)
                )
                .shadow(color: Color( "image.border"), radius: 5,x:2,y:2)
            
            //                    .shadow(radius: 10)
            
            
            
            VStack(alignment: .leading,spacing: 6) {
                Text(book.name)
                    .font(.system(.title3, design: .rounded))
                
                if let author = book.author {
                    if( author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false){
                        Text(author)
                            .font(.system(.subheadline))
                            .foregroundColor(.gray)
                    }
                }
                
                if let tagString = book.tags{
                    if !tagString.isEmpty {
                        HStack{
                            ForEach( tagString.split(separator: ",").map({Tag(name: String($0))})){tag in
                            
                                    Text(tag.name)
                                        .padding(3)
                                        .padding(.horizontal,5)
                                        .background(.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                        .font(.caption)
                            
                            }
                        }
                    }
                    
                }
                
                                
                HStack(alignment: .bottom,spacing: 6) {
                    if book.isDone{
                        Image(systemName: "clock.badge.checkmark.fill")
                            .foregroundColor(.green)
                    }else{
                        Image(systemName: "deskclock")
                           
                    }
                    
                    Text(book.readMinutes.asString())
                 
                }
                .font(.system (.subheadline,design: .rounded))
                //                        .foregroundColor(.gray)
            }
            .padding(.leading,8)
            .padding(.trailing,8)
            .padding(.top,10)
            
        }
        .padding(.vertical,2)
        .onAppear {
            loadCoverIfNeeded()
            buildThumbnailIfNeeded()
        }
        .onChange(of: coverKey) {
            loadCoverIfNeeded()
        }
//        .frame(height:120)
        
    }
    
    @ViewBuilder
    private var cover: some View {
        Group {
            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 85, height: 115 , alignment: .center)
        .clipped()
    }
    
    private func loadCoverIfNeeded() {
        let key = coverKey
        
        if let image = BookCoverImageCache.shared.image(for: key) {
            coverImage = image
            return
        }
        
        guard let thumbnailData = book.thumbnailImage else {
            coverImage = nil
            return
        }
        
        BookCoverImageLoader.shared.load(key: key, data: thumbnailData) { image in
            guard coverKey == key else { return }
            coverImage = image
        }
    }
    
    private func buildThumbnailIfNeeded() {
        guard book.thumbnailImage == nil else { return }
        
        let key = book.objectID.uriRepresentation().absoluteString
        let sourceData = book.image
        
        BookThumbnailGenerator.shared.generateIfNeeded(key: key, sourceData: sourceData) { thumbnailData in
            guard book.thumbnailImage == nil else { return }
            
            guard let thumbnailData else {
                loadOriginalCoverFallback(for: sourceData)
                return
            }
            
            book.thumbnailImage = thumbnailData
            loadCoverIfNeeded()
            do {
                try context.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func loadOriginalCoverFallback(for data: Data) {
        let key = coverKey
        
        BookCoverImageLoader.shared.load(key: key, data: data) { image in
            guard coverKey == key else { return }
            coverImage = image
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
