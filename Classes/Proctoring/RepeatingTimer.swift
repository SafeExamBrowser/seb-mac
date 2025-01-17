//
//  RepeatingTimer.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 30.04.24.
//

class RepeatingTimer {

    let timeInterval: TimeInterval
    let queue: DispatchQueue
    var repeating = true
    
    init(timeInterval: TimeInterval, queue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.queue = queue
    }
    
    init(timeInterval: TimeInterval, queue: DispatchQueue, repeating: Bool) {
        self.timeInterval = timeInterval
        self.queue = queue
        self.repeating = repeating
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(queue: self.queue)
        if repeating {
            t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        } else {
            t.schedule(deadline: .now() + self.timeInterval, repeating: DispatchTimeInterval.never)
        }
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
    
    func reset() {
        timer.cancel()
        resume()
    }
}
