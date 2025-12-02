//
//  JournalEntry.swift
//  HackChallengeJournalApp
//
//  Created by Ethan Khan on 12/1/25.
//

import Foundation

struct JournalEntry: Codable {
    let id: String
    let title: String
    let content: String
    let date: Date
    
    init(title: String, content: String) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.date = Date()
    }
}
