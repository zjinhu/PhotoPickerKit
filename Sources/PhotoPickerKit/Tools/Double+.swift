//
//  File.swift
//  
//
//  Created by HU on 2024/4/29.
//

import Foundation
public extension Double{
    func formatDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: TimeInterval(self)) ?? "00:00"
    }
}
