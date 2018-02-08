//
//  ViewToken.swift
//  NutView
//
//  Created by Filip Klembara on 8/11/17.
//
//

@available(*, deprecated, message: "Use without old")
struct OldViewToken {
    let name: String
    let head: [OldNutHeadProtocol]
    let body: [OldNutTokenProtocol]
    let layout: OldNutLayoutProtocol?

    init(name: String,
         head: [OldNutHeadProtocol] = [],
         body: [OldNutTokenProtocol],
         layout: OldNutLayoutProtocol? = nil) {

        self.name = name
        self.head = head
        self.body = body
        self.layout = layout
    }
}
