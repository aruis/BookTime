//
//  TimerTrack.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/2.
//

import Foundation

class TimerTrack:ObservableObject{
    
    var begin =  Date()
    
    @Published var count = 0
    var timer = Timer()
    
    
    static var shared: TimerTrack = {
        let instance = TimerTrack()
        // ... configure the instance
        // ...
        return instance
    }()
    
    private init() {}
    
    func start(callback: @escaping (Int)->() ){
        begin =  Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true ){ _ in            
            self.count += 1
            callback(self.count)
            
        }
    }
    
    func stop(){        
        count = 0
        timer.invalidate()
    }
    
}
