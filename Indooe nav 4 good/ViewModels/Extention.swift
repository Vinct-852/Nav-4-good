//
//  extention.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 18/11/2025.
//
import Foundation

extension Date {
    var logFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}
