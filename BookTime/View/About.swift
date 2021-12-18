//
//  About.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/7.
//

import SwiftUI
import StoreKit

struct About: View {
    var body: some View {
        
        NavigationView {
            VStack (alignment: .leading,spacing: 20){
                Text("""
          创作这个App的💡来源于我正在上小学二年级的👧🏻，她有项作业是每天要阅读30分钟，有了这个App，我就能更好地督促她读书打卡了。
          老师每学期都要统计孩子的阅读量，要求家长做好孩子的阅读记录，所以这个App可帮了我大忙了，因为她每年的阅读量都在百本左右，我平时真的很难持续跟踪记录她的阅读进度。现在，我只要从App导出阅读数据就可以了。
          这款App也帮我养成每天坚持阅读的习惯，您可以在这里找到我的[读书分享视频](https://space.bilibili.com/24370353/channel/seriesdetail?sid=320833)。也欢迎您发[邮件](mailto:cheetah_chugs.0g@icloud.com)给我，交流任何你想交流的事情。
          最后，希望您喜欢这款App，也祝您永远享受阅读的乐趣❤️
    """)
                //                .font(.caption)
                    .lineSpacing(4)
                //                .lineLimit(10)
                
                HStack{
                    Button(action: {
                        if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive })
                            as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }){
                        Text("期待您的评价\(Image(systemName: "face.smiling"))")
                    }
                }.frame(minWidth:0,maxWidth: .infinity)
                
                
                Spacer()
            }
            .padding()
            .navigationTitle("关于")
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
