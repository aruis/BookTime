//
//  TimerTrack.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/2.
//

import Foundation

class TimerTrack:ObservableObject{
    
    @Published var count = 0
    var timer = Timer()
    
    static var shared: TimerTrack = {
        let instance = TimerTrack()
        // ... configure the instance
        // ...
        return instance
    }()
    
    private init() {}
    
    func start(){
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true ){_ in
            print("x")
            self.count += 1
        }
    }
    
    func stop(){
        print("stop")
        count = 0
        timer.invalidate()
    }
    
}
