//
//  WeakContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 15/07/2026.
//

struct WeakContainer<T: AnyObject, Context> {
    let id: ObjectIdentifier
    weak let object: T?
    let context: Context?
    
    init(_ object: T, context: Context? = nil) {
        self.id = ObjectIdentifier(object)
        self.object = object
        self.context = context
    }
}
