//
//  XMLDelegate.swift
//  ASR
//
//  Created by Soren Marcelino on 15/03/2023.
//

import Foundation

class XMLDelegate: NSObject, XMLParserDelegate {
    var currentElement: String?
    var currentText: String?
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText? += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = nil
        if elementName == "audio" {
            print(currentText)
        }
    }
}
