//
//  FIFOBuffer.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 18.08.2024.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation

public class FIFOBuffer {
    
    private lazy var fifoDispatchQueue = DispatchQueue(label: "org.safeexambrowser.SEB.\(UUID())", qos: .background)
    private var queue: Queue<AnyHashable> = Queue()
    
    struct Queue<T: Hashable> {
        
        var list = [T]()
        
        mutating func enqueue(_ element: T) {
            list.append(element)
        }
        
        mutating func dequeue() -> T? {
            if !list.isEmpty {
                return list.removeFirst()
            } else {
                return nil
            }
        }
        
        mutating func remove(_ element: T) -> Bool {
            if !list.isEmpty {
                list = list.filter {$0 != element }
                return true
            }
            return false
        }
        
        func copyFirst() -> T? {
            if !list.isEmpty {
                return list.first
            } else {
                return nil
            }
        }
        
        var isEmpty: Bool {
            return list.isEmpty
        }

        var count: Int {
            return list.count
        }
    }
    
    var isEmpty: Bool {
        return queue.isEmpty
    }

    var count: Int {
        return queue.count
    }
    
    func pushObject(_ object: AnyHashable) {
        fifoDispatchQueue.async {
            self.queue.enqueue(object)
        }
    }
    
    func popObject() -> AnyHashable? {
        guard let object = self.queue.dequeue() else {
            return nil
        }
        return object
    }
    
    func removeObject(_ object: AnyHashable) -> Bool {
        return self.queue.remove(object)
    }
    
    func copyObject() -> AnyHashable? {
        guard let object = self.queue.copyFirst() else {
            return nil
        }
        return object
    }
}
