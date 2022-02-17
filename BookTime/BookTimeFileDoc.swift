//
//  BookTimeFileDoc.swift
//  BookTime
//
//  Created by Liu Rui on 2022/1/29.
//

//import Foundation
import SwiftUI
import UniformTypeIdentifiers


struct BookTimeFileDoc: FileDocument {
    
    static var readableContentTypes: [UTType] { [.text] }

    var message: String

    init(message: String) {
        self.message = message
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        message = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: message.data(using: .utf8)!)
    }
    
}
