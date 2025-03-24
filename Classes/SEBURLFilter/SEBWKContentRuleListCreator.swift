//
//  SEBWKContentRuleListCreator.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 03.02.2025.
//

import Foundation
import CocoaLumberjackSwift

private struct Rule: Codable {
    let trigger: Trigger
    let action: Action
}

private struct Trigger: Codable {
    let urlFilter: String
    
    enum CodingKeys: String, CodingKey {
        case urlFilter = "url-filter"
    }
}

private struct Action: Codable {
    let type: String
    let selector: String?
    
    init(type: String) {
        self.type = type
        self.selector = nil
    }
    
    init(type: String, selector: String?) {
        self.type = type
        self.selector = selector
    }
}

private struct ActionType: Codable {
    static let block = "block"
    static let allow = "ignore-previous-rules"
    static let cssDisplayNone = "css-display-none"
}

@objc public class SEBWKContentRuleListCreator: NSObject {

    let joinString = ",\n"
    let allowUploads: Bool
    
    init(allowUploads: Bool = false) {
        self.allowUploads = allowUploads
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    private func encodeRule(_ rule: Rule) -> String {
        do {
            let ruleStringData = try JSONEncoder().encode(rule)
            let ruleStringAsString = String(data: ruleStringData, encoding: .utf8)!
            return ruleStringAsString
        } catch let error as NSError {
            DDLogError("Error encoding rule '\(rule)': \(error)")
            return ""
        }
    }

    @objc public func contentRuleList(allowFilterStrings: [String], blockFilterStrings: [String]) -> String {
        
        var contentRuleString = ""
        if !(allowFilterStrings.isEmpty && blockFilterStrings.isEmpty) {
            let ruleStruct = Rule(trigger: Trigger(urlFilter: ".*"), action: Action(type: ActionType.block))
            contentRuleString = encodeRule(ruleStruct)
            
            for allowFilterString in allowFilterStrings {
                let ruleStruct = Rule(trigger: Trigger(urlFilter: allowFilterString), action: Action(type: ActionType.allow))
                let ruleStringAsJSONString = encodeRule(ruleStruct)
                contentRuleString += joinString + ruleStringAsJSONString
            }
            
            for blockFilterString in blockFilterStrings {
                let ruleStruct = Rule(trigger: Trigger(urlFilter: blockFilterString), action: Action(type: ActionType.block))
                let ruleStringAsJSONString = encodeRule(ruleStruct)
                contentRuleString += joinString + ruleStringAsJSONString
            }
        }
        
#if os(iOS)
        if !allowUploads {
            let blockChooseFileRuleStruct = Rule(trigger: Trigger(urlFilter: ".*"), action: Action(type: ActionType.cssDisplayNone, selector: "[type=file]"))
            contentRuleString += contentRuleString.isEmpty ? "" : joinString
            contentRuleString += encodeRule(blockChooseFileRuleStruct)
            // This is a specific filter to block the class of a drag-and-drop/choose file for upload box in Ans
            let blockFileSelectorButtonRuleStruct = Rule(trigger: Trigger(urlFilter: ".*"), action: Action(type: ActionType.cssDisplayNone, selector: ".upload-redactor-box"))
            contentRuleString += contentRuleString.isEmpty ? "" : joinString
            contentRuleString += encodeRule(blockFileSelectorButtonRuleStruct)
        }
#endif
        contentRuleString = "[" + contentRuleString + "]"
        return contentRuleString
    }
}
