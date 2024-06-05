//
//  About.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/7.
//

import SwiftUI
import StoreKit

struct About: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        NavigationView {
            ScrollView{
                VStack (alignment:.trailing, spacing: 10){
                    Text("""
           The idea💡 for creating this app came from my daughter👧🏻 who is in the second grade of elementary school. She has an assignment that requires 30 minutes of reading every day. With this app, I can better urge her to read and clock in.
           The teacher counts the children's reading volume every semester and asks parents to make a record of their children's reading, so this app has helped me a lot, because her annual reading volume is about 100 books, it is really difficult for me to keep track of it. Record her reading progress. Now, I only need to export the reading data from the App.
           This App also helped me develop the habit of reading every day. You can find my [Reading Sharing Video](https://space.bilibili.com/24370353/channel/seriesdetail?sid=320833) here. You are also welcome to send [mail](mailto:cheetah_chugs.0g@icloud.com) to me to communicate anything you want to communicate.
           Finally, I hope you like this App, and I wish you always enjoy the fun of reading ❤️
    """)
                    //                .font(.caption)
                    .lineSpacing(4)
                    //                .lineLimit(10)
                    
                    Text("- at the end of 2021.")
                    //                        .multilineTextAlignment(.trailing)
                    
                    
                    Button(action: {
                        if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive })
                            as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }){
                        Text("Looking forward to your evaluation\(Image(systemName: "face.smiling"))")
                    }
                    
                    
                    
                    
                }
                .padding()
                .ignoresSafeArea()
                .navigationTitle("About")
            }
            .overlay(alignment: .bottom, content: {
                Text("苏ICP备2024057896号-1A")
                    .font(.callout)
                    .foregroundStyle(.secondary)

            })
            .toolbar{
                Button(action: {
                    dismiss()
                }){
                    Image(systemName: "xmark.circle")
                }
                
            }
            
            
        }
        
    }
}

struct About_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView{
            About()
        }
        
    }
}
