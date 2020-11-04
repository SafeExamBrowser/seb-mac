

const SkipSeconds = 15;
const MinimumSizeToShowAnyControl = 47;
const MaximumSizeToShowSmallProminentControl = 88;

let mediaControlsHost;

// This is called from HTMLMediaElement::ensureMediaControlsInjectedScript().
function createControls(shadowRoot, media, host)
{
    if (host) {
        mediaControlsHost = host;
        iconService.mediaControlsHost = host;
        shadowRoot.appendChild(document.createElement("style")).textContent = host.shadowRootCSSText;
    }

    return new MediaController(shadowRoot, media, host);
}

function UIString(stringToLocalize, replacementString)
{
    let allLocalizedStrings = {};
    try {
        allLocalizedStrings = UIStrings;
    } catch (error) {}

    const localizedString = allLocalizedStrings[stringToLocalize];
    if (!localizedString)
        return stringToLocalize;

    if (replacementString)
        return localizedString.replace("%s", replacementString);

    return localizedString;
}

function formatTimeByUnit(value)
{
    const time = value || 0;
    const absTime = Math.abs(time);
    return {
        seconds: Math.floor(absTime % 60).toFixed(0),
        minutes: Math.floor((absTime / 60) % 60).toFixed(0),
        hours: Math.floor(absTime / (60 * 60)).toFixed(0)
    };
}

function unitizeTime(value, unit)
{
    let returnedUnit = UIString(unit);
    if (value > 1)
        returnedUnit = UIString(`${unit}s`);

    return `${value} ${returnedUnit}`;
}

function formattedStringForDuration(timeInSeconds)
{
    if (mediaControlsHost)
        return mediaControlsHost.formattedStringForDuration(Math.abs(timeInSeconds));
    else
        return "";
}
class GestureRecognizer
{

    constructor(target = null, delegate = null)
    {
        this._targetPointers = new Map;

        this.modifierKeys = {
            alt : false,
            ctrl : false,
            meta : false,
            shift : false
        };

        this._state = GestureRecognizer.States.Possible;
        this._enabled = true;

        this.target = target;
        this.delegate = delegate;
    }

    // Public

    get state()
    {
        return this._state;
    }

    set state(state)
    {
        if (this._state === state && state !== GestureRecognizer.States.Changed)
            return;

        this._state = state;
        if (this.delegate && typeof this.delegate.gestureRecognizerStateDidChange === "function")
            this.delegate.gestureRecognizerStateDidChange(this);
    }

    get target()
    {
        return this._target;
    }

    set target(target)
    {
        if (!target || this._target === target)
            return;

        this._target = target;
        this._initRecognizer();
    }

    get numberOfTouches()
    {
        return this._targetPointers.size;
    }

    get enabled()
    {
        return this._enabled;
    }

    set enabled(enabled)
    {
        if (this._enabled === enabled)
            return;

        this._enabled = enabled;

        if (!enabled) {
            if (this.numberOfTouches === 0) {
                this._removeTrackingListeners();
                this.reset();
            } else
                this.enterCancelledState();
        }

        this._updateBaseListeners();
    }

    reset()
    {
        // Implemented by subclasses.
    }

    locationInElement(element)
    {
        const p = new DOMPoint;
        const count = this._targetPointers.size;
        if (!count)
            return p;
        this._targetPointers.forEach(function (pointer) {
            p.x += pointer.pageX;
            p.y += pointer.pageY;
        });
        p.x /= count;
        p.y /= count;

        if (!element)
            return p;

        // FIXME: are WebKitPoint and DOMPoint interchangeable?
        const wkPoint = window.webkitConvertPointFromPageToNode(element, new WebKitPoint(p.x, p.y));
        return new DOMPoint(wkPoint.x, wkPoint.y);
    }

    locationInClient()
    {
        const p = new DOMPoint;
        const count = this._targetPointers.size;
        if (!count)
            return p;
        this._targetPointers.forEach(function (pointer) {
            p.x += pointer.clientX;
            p.y += pointer.clientY;
        });
        p.x /= count;
        p.y /= count;

        return p;
    }

    touchesBegan(event)
    {
        if (event.currentTarget !== this._target)
            return;

        window.addEventListener(GestureRecognizer.Events.PointerMove, this, true);
        window.addEventListener(GestureRecognizer.Events.PointerUp, this, true);
        window.addEventListener(GestureRecognizer.Events.PointerCancel, this, true);
        this.enterPossibleState();
    }

    touchesMoved(event)
    {
        // Implemented by subclasses.
    }

    touchesEnded(event)
    {
        // Implemented by subclasses.
    }

    touchesCancelled(event)
    {
        // Implemented by subclasses.
    }

    gestureBegan(event)
    {
        if (event.currentTarget !== this._target)
            return;

        this._target.addEventListener(GestureRecognizer.Events.GestureChange, this, true);
        this._target.addEventListener(GestureRecognizer.Events.GestureEnd, this, true);
        this.enterPossibleState();
    }

    gestureChanged(event)
    {
        // Implemented by subclasses.
    }

    gestureEnded(event)
    {
        // Implemented by subclasses.
    }

    enterPossibleState()
    {
        this.state = GestureRecognizer.States.Possible;
    }

    enterBeganState()
    {
        if (this.delegate && typeof this.delegate.gestureRecognizerShouldBegin === "function" && !this.delegate.gestureRecognizerShouldBegin(this)) {
            this.enterFailedState();
            return;
        }
        this.state = GestureRecognizer.States.Began;
    }

    enterEndedState()
    {
        this.state = GestureRecognizer.States.Ended;
        this._removeTrackingListeners();
        this.reset();
    }

    enterCancelledState()
    {
        this.state = GestureRecognizer.States.Cancelled;
        this._removeTrackingListeners();
        this.reset();
    }

    enterFailedState()
    {
        this.state = GestureRecognizer.States.Failed;
        this._removeTrackingListeners();
        this.reset();
    }

    enterChangedState()
    {
        this.state = GestureRecognizer.States.Changed;
    }

    enterRecognizedState()
    {
        this.state = GestureRecognizer.States.Recognized;
    }

    // Protected

    handleEvent(event)
    {
        this._updateTargetTouches(event);
        this._updateKeyboardModifiers(event);

        switch (event.type) {
        case GestureRecognizer.Events.PointerDown:
            this.touchesBegan(event);
            break;
        case GestureRecognizer.Events.PointerMove:
            this.touchesMoved(event);
            break;
        case GestureRecognizer.Events.PointerUp:
            this.touchesEnded(event);
            break;
        case GestureRecognizer.Events.PointerCancel:
            this.touchesCancelled(event);
            break;
        case GestureRecognizer.Events.GestureStart:
            this.gestureBegan(event);
            break;
        case GestureRecognizer.Events.GestureChange:
            this.gestureChanged(event);
            break;
        case GestureRecognizer.Events.GestureEnd:
            this.gestureEnded(event);
            break;
        }
    }

    // Private

    _initRecognizer()
    {
        this.reset();
        this.state = GestureRecognizer.States.Possible;

        this._updateBaseListeners();
    }

    _updateBaseListeners()
    {
        if (!this._target)
            return;

        if (this._enabled) {
            this._target.addEventListener(GestureRecognizer.Events.PointerDown, this);
            if (GestureRecognizer.SupportsGestures)
                this._target.addEventListener(GestureRecognizer.Events.GestureStart, this);
        } else {
            this._target.removeEventListener(GestureRecognizer.Events.PointerDown, this);
            if (GestureRecognizer.SupportsGestures)
                this._target.removeEventListener(GestureRecognizer.Events.GestureStart, this);
        }
    }

    _removeTrackingListeners()
    {
        window.removeEventListener(GestureRecognizer.Events.PointerMove, this, true);
        window.removeEventListener(GestureRecognizer.Events.PointerUp, this, true);
        window.removeEventListener(GestureRecognizer.Events.PointerCancel, this, true);
        this._target.removeEventListener(GestureRecognizer.Events.GestureChange, this, true);
        this._target.removeEventListener(GestureRecognizer.Events.GestureEnd, this, true);

        this._targetPointers = new Map;
    }

    _updateTargetTouches(event)
    {
        if (!(event instanceof PointerEvent))
            return;

        if (event.type === GestureRecognizer.Events.PointerDown) {
            this._targetPointers.set(event.pointerId, event);
            return;
        }

        if (event.type === GestureRecognizer.Events.PointerMove) {
            this._targetPointers.set(event.pointerId, event);
            return;
        }

        this._targetPointers.delete(event.pointerId);
    }

    _updateKeyboardModifiers(event)
    {
        this.modifierKeys.alt = event.altKey;
        this.modifierKeys.ctrl = event.ctrlKey;
        this.modifierKeys.meta = event.metaKey;
        this.modifierKeys.shift = event.shiftKey;
    }

}

GestureRecognizer.SupportsTouches = "createTouch" in document;
GestureRecognizer.SupportsGestures = !!window.GestureEvent;

GestureRecognizer.States = {
    Possible   : "possible",
    Began      : "began",
    Changed    : "changed",
    Ended      : "ended",
    Cancelled  : "cancelled",
    Failed     : "failed",
    Recognized : "ended"
};

GestureRecognizer.Events = {
    PointerDown    : "pointerdown",
    PointerMove    : "pointermove",
    PointerUp      : "pointerup",
    PointerCancel  : "pointercancel",
    GestureStart   : "gesturestart",
    GestureChange  : "gesturechange",
    GestureEnd     : "gestureend"
};

const MOVE_TOLERANCE = GestureRecognizer.SupportsTouches ? 40 : 0;
const WAITING_FOR_NEXT_TAP_TO_START_TIMEOUT = 350;
const WAITING_FOR_TAP_COMPLETION_TIMEOUT = 750;

class TapGestureRecognizer extends GestureRecognizer
{

    constructor(target, delegate)
    {
        super(target, delegate);

        this.numberOfTapsRequired = 1;
        this.numberOfTouchesRequired = 1;
        this.allowsRightMouseButton = false;
    }

    // Protected

    touchesBegan(event)
    {
        if (event.currentTarget !== this.target)
            return;

        if (event.button === 2 && !this.allowsRightMouseButton)
            return;

        super.touchesBegan(event);

        if (this.numberOfTouches !== this.numberOfTouchesRequired) {
            this.enterFailedState();
            return;
        }

        this._startPoint = super.locationInElement();
        this._startClientPoint = super.locationInClient();

        this._rewindTimer(WAITING_FOR_TAP_COMPLETION_TIMEOUT);
    }

    touchesMoved(event)
    {
        const touchLocation = super.locationInElement();
        const distance = Math.sqrt(Math.pow(this._startPoint.x - touchLocation.x, 2) + Math.pow(this._startPoint.y - touchLocation.y, 2));
        if (distance > MOVE_TOLERANCE)
            this.enterFailedState();
    }

    touchesEnded(event)
    {
        this._taps++;

        if (this._taps === this.numberOfTapsRequired) {
            // We call prevent default here to override the potential double-tap-to-zoom
            // behavior of the browser.
            event.preventDefault();

            this.enterRecognizedState();
            this.reset();
        }

        this._rewindTimer(WAITING_FOR_NEXT_TAP_TO_START_TIMEOUT);
    }

    reset()
    {
        this._taps = 0;
        this._clearTimer();
    }

    locationInElement(element)
    {
        const p = this._startPoint || new DOMPoint;

        if (!element)
            return p;

        // FIXME: are WebKitPoint and DOMPoint interchangeable?
        const wkPoint = window.webkitConvertPointFromPageToNode(element, new WebKitPoint(p.x, p.y));
        return new DOMPoint(wkPoint.x, wkPoint.y);
    }

    locationInClient()
    {
        return this._startClientPoint || new DOMPoint;
    }

    // Private

    _clearTimer()
    {
        window.clearTimeout(this._timerId);
        delete this._timerId;
    }

    _rewindTimer(timeout)
    {
        this._clearTimer();
        this._timerId = window.setTimeout(this._timerFired.bind(this), timeout);
    }

    _timerFired()
    {
        this.enterFailedState();
    }

}

const MAXIMUM_TIME_FOR_RECORDING_GESTURES = 100;
const MAXIMUM_DECELERATION_TIME = 500;

class PinchGestureRecognizer extends GestureRecognizer
{

    constructor(target, delegate)
    {
        super(target, delegate);

        this.scaleThreshold = 0;
        this._scaledMinimumAmount = false;
    }

    // Public

    get velocity()
    {
        const lastGesture = this._gestures[this._gestures.length - 1];
        if (!lastGesture)
            return this._velocity;

        const elapsedTime = Date.now() - (lastGesture.timeStamp + MAXIMUM_TIME_FOR_RECORDING_GESTURES);
        if (elapsedTime <= 0)
            return this._velocity;

        const f = Math.max((MAXIMUM_DECELERATION_TIME - elapsedTime) / MAXIMUM_DECELERATION_TIME, 0);
        return this._velocity * f;
    }

    // Protected

    touchesBegan(event)
    {
        if (event.currentTarget !== this.target)
            return;

        // Additional setup for when the the platform doesn't natively
        // provide us with gesture events.
        if (!GestureRecognizer.SupportsGestures) {
            // A pinch gesture can only be performed with 2 fingers, anything more
            // and we failed our gesture.
            if (this.numberOfTouches > 2) {
                this.enterFailedState();
                return;
            }

            // We can only start tracking touches with 2 fingers.
            if (this.numberOfTouches !== 2)
                return;

            this._startDistance = this._distance();

            // We manually add a start value so that we always have 2 entries in the
            // _gestures array so that we don't have to check for the existence of 2
            // entries when computing velocity.
            this._recordGesture(1);

            this._scaledMinimumAmount = false;
            this._updateStateWithEvent(event);
        } else if (this.numberOfTouches !== 2) {
            // When we support gesture events, we only care about the case where we're
            // using two fingers.
            return;
        }

        super.touchesBegan(event);
    }

    touchesMoved(event)
    {
        // This method only needs to be overriden in the case where the platform
        // doesn't natively provide us with gesture events.
        if (GestureRecognizer.SupportsGestures)
            return;

        if (this.numberOfTouches !== 2)
            return;

        this._updateStateWithEvent(event);
    }

    touchesEnded(event)
    {
        // This method only needs to be overriden in the case where the platform
        // doesn't natively provide us with gesture events.
        if (GestureRecognizer.SupportsGestures)
            return;

        // If we don't have the required number of touches or have not event
        // obtained 2 fingers, then there's nothing for us to do.
        if (this.numberOfTouches >= 2 || !this._startDistance)
            return;

        if (this._scaledMinimumAmount)
            this.enterEndedState();
        else
            this.enterFailedState();
    }

    gestureBegan(event)
    {
        super.gestureBegan(event);

        // We manually add a start value so that we always have 2 entries in the
        // _gestures array so that we don't have to check for the existence of 2
        // entries when computing velocity.
        this._recordGesture(event.scale);

        this._scaledMinimumAmount = false;
        this._updateStateWithEvent(event);

        event.preventDefault();
    }

    gestureChanged(event)
    {
        event.preventDefault();

        this._updateStateWithEvent(event);
    }

    gestureEnded(event)
    {
        if (this._scaledMinimumAmount)
            this.enterEndedState();
        else
            this.enterFailedState();
    }

    reset()
    {
        this.scale = 1;
        this._velocity = 0;
        this._gestures = [];
        delete this._startDistance;
    }

    // Private

    _recordGesture(scale)
    {
        const currentTime = Date.now();
        const count = this._gestures.push({
            scale: scale,
            timeStamp: currentTime
        });

        // We want to keep at least two gestures at all times.
        if (count <= 2)
            return;

        const scaleDirection = this._gestures[count - 1].scale >= this._gestures[count - 2].scale;
        let i = count - 3;
        for (; i >= 0; --i) {
            let gesture = this._gestures[i];
            if (currentTime - gesture.timeStamp > MAXIMUM_TIME_FOR_RECORDING_GESTURES ||
                this._gestures[i + 1].scale >= gesture.scale !== scaleDirection)
                break;
        }

        if (i > 0)
            this._gestures = this._gestures.slice(i + 1);
    }

    _updateStateWithEvent(event)
    {
        const scaleSinceStart = GestureRecognizer.SupportsGestures ? event.scale : this._distance() / this._startDistance;

        if (!this._scaledMinimumAmount) {
            if (Math.abs(1 - scaleSinceStart) >= this.scaleThreshold) {
                this._scaledMinimumAmount = true;
                this.scale = 1;
                this.enterBeganState();
            }
            return;
        }

        this._recordGesture(scaleSinceStart);

        const oldestGesture = this._gestures[0];
        const ds = scaleSinceStart - oldestGesture.scale;
        const dt = Date.now() - oldestGesture.timeStamp;
        this._velocity = (dt === 0) ? 0 : ds / dt * 1000;

        this.scale *= scaleSinceStart / this._gestures[this._gestures.length - 2].scale;

        this.enterChangedState();
    }

    _distance()
    {
        console.assert(this.numberOfTouches === 2);

        const firstTouch = this._targetTouches[0];
        const firstTouchPoint = new DOMPoint(firstTouch.pageX, firstTouch.pageY);

        const secondTouch = this._targetTouches[1];
        const secondTouchPoint = new DOMPoint(secondTouch.pageX, secondTouch.pageY);

        return Math.sqrt(Math.pow(firstTouchPoint.x - secondTouchPoint.x, 2) + Math.pow(firstTouchPoint.y - secondTouchPoint.y, 2));
    }

}

const scheduler = new class
{

    constructor()
    {
        this._frameID = -1;
        this._layoutCallbacks = new Set;
    }

    // Public

    get hasScheduledLayoutCallbacks()
    {
        return this._frameID !== -1 || this._layoutCallbacks.size > 0;
    }

    scheduleLayout(callback)
    {
        if (typeof callback !== "function")
            return;

        this._layoutCallbacks.add(callback);
        this._requestFrameIfNeeded();
    }

    unscheduleLayout(callback)
    {
        if (typeof callback !== "function")
            return;

        this._layoutCallbacks.delete(callback);
    }

    flushScheduledLayoutCallbacks()
    {
        this._frameDidFire();
    }

    // Private

    _requestFrameIfNeeded()
    {
        if (this._frameID === -1 && this._layoutCallbacks.size > 0)
            this._frameID = window.requestAnimationFrame(this._frameDidFire.bind(this));
    }

    _frameDidFire()
    {
        if (typeof scheduler.frameWillFire === "function")
            scheduler.frameWillFire();

        this._layout();
        this._frameID = -1;
        this._requestFrameIfNeeded();

        if (typeof scheduler.frameDidFire === "function")
            scheduler.frameDidFire();
    }

    _layout()
    {
        // Layouts are not re-entrant.
        const layoutCallbacks = this._layoutCallbacks;
        this._layoutCallbacks = new Set;

        for (let callback of layoutCallbacks)
            callback();
    }

};

const dirtyNodes = new Set;
const nodesRequiringChildrenUpdate = new Set;

class LayoutNode
{

    constructor(stringOrElement)
    {

        if (!stringOrElement)
            this.element = document.createElement("div");
        else if (stringOrElement instanceof Element)
            this.element = stringOrElement;
        else if (typeof stringOrElement === "string" || stringOrElement instanceof String)
            this.element = elementFromString(stringOrElement);

        this._parent = null;
        this._children = [];

        this._x = 0;
        this._y = 0;
        this._width = 0;
        this._height = 0;
        this._visible = true;

        this._needsLayout = false;
        this._dirtyProperties = new Set;

        this._pendingDOMManipulation = LayoutNode.DOMManipulation.None;
    }

    // Public

    get x()
    {
        return this._x;
    }

    set x(x)
    {
        if (x === this._x)
            return;

        this._x = x;
        this.markDirtyProperty("x");
    }

    get y()
    {
        return this._y;
    }

    set y(y)
    {
        if (y === this._y)
            return;

        this._y = y;
        this.markDirtyProperty("y");
    }

    get width()
    {
        return this._width;
    }

    set width(width)
    {
        if (width === this._width)
            return;

        this._width = width;
        this.markDirtyProperty("width");
        this.layout();
    }

    get height()
    {
        return this._height;
    }

    set height(height)
    {
        if (height === this._height)
            return;

        this._height = height;
        this.markDirtyProperty("height");
        this.layout();
    }

    get visible()
    {
        return this._visible;
    }

    set visible(flag)
    {
        if (flag === this._visible)
            return;

        this._visible = flag;
        this.markDirtyProperty("visible");
    }

    get needsLayout()
    {
        return this._needsLayout || this._pendingDOMManipulation !== LayoutNode.DOMManipulation.None || this._dirtyProperties.size > 0;
    }

    set needsLayout(flag)
    {
        if (this.needsLayout === flag)
            return;

        this._needsLayout = flag;
        this._updateDirtyState();
    }

    get parent()
    {
        return this._parent;
    }

    get children()
    {
        return this._children;
    }

    set children(children)
    {
        if (children.length === this._children.length) {
            let arraysDiffer = false;
            for (let i = children.length - 1; i >= 0; --i) {
                if (children[i] !== this._children[i]) {
                    arraysDiffer = true;
                    break;
                }
            }
            if (!arraysDiffer)
                return;
        }

        this._updatingChildren = true;

        while (this._children.length)
            this.removeChild(this._children[0]);

        for (let child of children)
            this.addChild(child);

        delete this._updatingChildren;
        this.didChangeChildren();
    }

    parentOfType(type)
    {
        let node = this;
        while (node = node._parent) {
            if (node instanceof type)
                return node;
        }
        return null;
    }

    addChild(child, index)
    {
        child.remove();

        if (index === undefined || index < 0 || index > this._children.length)
            index = this._children.length;

        this._children.splice(index, 0, child);
        child._parent = this;

        if (!this._updatingChildren)
            this.didChangeChildren();

        child._markNodeManipulation(LayoutNode.DOMManipulation.Addition);

        return child;
    }

    insertBefore(newSibling, referenceSibling)
    {
        return this.addChild(newSibling, this._children.indexOf(referenceSibling));
    }

    insertAfter(newSibling, referenceSibling)
    {
        const index = this._children.indexOf(referenceSibling);
        return this.addChild(newSibling, index + 1);
    }

    removeChild(child)
    {
        if (child._parent !== this)
            return;

        const index = this._children.indexOf(child);
        if (index === -1)
            return;

        this.willRemoveChild(child);
        this._children.splice(index, 1);
        child._parent = null;

        if (!this._updatingChildren)
            this.didChangeChildren();

        child._markNodeManipulation(LayoutNode.DOMManipulation.Removal);

        return child;
    }

    remove()
    {
        if (this._parent instanceof LayoutNode)
            return this._parent.removeChild(this);
    }

    markDirtyProperty(propertyName)
    {
        const hadProperty = this._dirtyProperties.has(propertyName);
        this._dirtyProperties.add(propertyName);

        if (!hadProperty)
            this._updateDirtyState();
    }

    // Protected

    layout()
    {
        // Implemented by subclasses.
    }

    commit()
    {
        if (this._pendingDOMManipulation === LayoutNode.DOMManipulation.Removal) {
            const parent = this.element.parentNode;
            if (parent)
                parent.removeChild(this.element);
        }
    
        for (let propertyName of this._dirtyProperties)
            this.commitProperty(propertyName);

        this._dirtyProperties.clear();

        if (this._pendingDOMManipulation === LayoutNode.DOMManipulation.Addition)
            nodesRequiringChildrenUpdate.add(this.parent);
    }

    commitProperty(propertyName)
    {
        const style = this.element.style;

        switch (propertyName) {
        case "x":
            style.left = `${this._x}px`;
            break;
        case "y":
            style.top = `${this._y}px`;
            break;
        case "width":
            style.width = `${this._width}px`;
            break;
        case "height":
            style.height = `${this._height}px`;
            break;
        case "visible":
            if (this._visible)
                style.removeProperty("display");
            else
                style.display = "none";
            break;
        }
    }

    willRemoveChild(child)
    {
        // Implemented by subclasses.
    }

    didChangeChildren()
    {
        // Implemented by subclasses.
    }

    // Private

    _markNodeManipulation(manipulation)
    {
        this._pendingDOMManipulation = manipulation;
        this._updateDirtyState();
    }

    _updateDirtyState()
    {
        if (this.needsLayout) {
            dirtyNodes.add(this);
            scheduler.scheduleLayout(performScheduledLayout);
        } else {
            dirtyNodes.delete(this);
            if (dirtyNodes.size === 0)
                scheduler.unscheduleLayout(performScheduledLayout);
        }
    }

    _updateChildren()
    {
        let nextChildElement = null;
        const element = this.element;
        for (let i = this.children.length - 1; i >= 0; --i) {
            let child = this.children[i];
            let childElement = child.element;

            if (child._pendingDOMManipulation === LayoutNode.DOMManipulation.Addition) {
                element.insertBefore(childElement, nextChildElement);
                child._pendingDOMManipulation = LayoutNode.DOMManipulation.None;
            }

            nextChildElement = childElement;
        }
    }

}

LayoutNode.DOMManipulation = {
    None:     0,
    Removal:  1,
    Addition: 2
};

function performScheduledLayout()
{
    const previousDirtyNodes = Array.from(dirtyNodes);
    dirtyNodes.clear();
    previousDirtyNodes.forEach(node => {
        node._needsLayout = false;
        node.layout();
        node.commit();
    });

    nodesRequiringChildrenUpdate.forEach(node => node._updateChildren());
    nodesRequiringChildrenUpdate.clear();
}

function elementFromString(elementString)
{
    const element = document.createElement("div");
    element.innerHTML = elementString;
    return element.firstElementChild;
}


const LayoutTraits = {
    Unknown        : 0,
    macOS          : 1 << 0,
    iOS            : 1 << 1,
    Fullscreen     : 1 << 2,
    Compact        : 1 << 3
};

class LayoutItem extends LayoutNode
{

    constructor({ element = null, layoutDelegate = null } = {})
    {
        super(element);

        this.layoutDelegate = layoutDelegate;
    }

    // Public

    get layoutTraits()
    {
        return (this.layoutDelegate && this.layoutDelegate.layoutTraits) || LayoutTraits.Unknown;
    }

}


const Icons = {
    Airplay         : { name: "Airplay", type: "svg", label: UIString("AirPlay") },
    AirplayPlacard  : { name: "airplay-placard", type: "png", label: UIString("AirPlay") },
    EnterFullscreen : { name: "EnterFullscreen", type: "svg", label: UIString("Enter Full Screen") },
    EnterPiP        : { name: "PipIn", type: "svg", label: UIString("Enter Picture in Picture") },
    ExitFullscreen  : { name: "ExitFullscreen", type: "svg", label: UIString("Exit Full Screen") },
    Forward         : { name: "Forward", type: "svg", label: UIString("Forward") },
    InvalidCompact  : { name: "InvalidCompact", type: "pdf", label: UIString("Invalid") },
    InvalidPlacard  : { name: "invalid-placard", type: "png", label: UIString("Invalid") },
    Pause           : { name: "Pause", type: "svg", label: UIString("Pause") },
    PiPPlacard      : { name: "pip-placard", type: "png", label: UIString("Picture in Picture") },
    Play            : { name: "Play", type: "svg", label: UIString("Play") },
    PlayCompact     : { name: "PlayCompact", type: "pdf", label: UIString("Play") },
    Rewind          : { name: "Rewind", type: "svg", label: UIString("Rewind") },
    SkipBack        : { name: "SkipBack15", type: "svg", label: UIString("Skip Back %s Seconds", SkipSeconds) },
    SkipForward     : { name: "SkipForward15", type: "svg", label: UIString("Skip Forward %s Seconds", SkipSeconds) },
    SpinnerCompact  : { name: "ActivityIndicatorSpriteCompact", type: "png", label: UIString("Loading…") },
    Tracks          : { name: "MediaSelector", type: "svg", label: UIString("Media Selection") },
    Volume          : { name: "VolumeHi", type: "svg", label: UIString("Mute") },
    VolumeRTL       : { name: "VolumeHi-RTL", type: "svg", label: UIString("Mute") },
    VolumeDown      : { name: "VolumeLo", type: "svg", label: UIString("Volume Down") },
    VolumeMuted     : { name: "Mute", type: "svg", label: UIString("Unmute") },
    VolumeMutedRTL  : { name: "Mute-RTL", type: "svg", label: UIString("Unmute") },
    VolumeUp        : { name: "VolumeHi", type: "svg", label: UIString("Volume Up") }
};

const MimeTypes = {
    "pdf": "application/pdf",
    "png": "image/png",
    "svg": "image/svg+xml"
};

const IconsWithFullscreenVariants = [Icons.Airplay, Icons.Tracks, Icons.EnterPiP];

const iconService = new class IconService {

    constructor()
    {
        this.images = {};
    }

    // Public

    imageForIconAndLayoutTraits(icon, layoutTraits)
    {
        const [fileName, platform] = this._fileNameAndPlatformForIconAndLayoutTraits(icon, layoutTraits);
        const path = `${platform}/${fileName}.${icon.type}`;

        let image = this.images[path];
        if (image)
            return image;

        image = this.images[path] = new Image;

        if (this.mediaControlsHost)
            image.src = `data:${MimeTypes[icon.type]};base64,${this.mediaControlsHost.base64StringForIconNameAndType(fileName, icon.type)}`;
        else
            image.src = `${this.directoryPath}/${path}`;

        return image;
    }

    // Private

    _fileNameAndPlatformForIconAndLayoutTraits(icon, layoutTraits)
    {
        let platform;
        if (layoutTraits & LayoutTraits.macOS)
            platform = "macOS";
        else if (layoutTraits & LayoutTraits.iOS || layoutTraits & LayoutTraits.Compact)
            platform = "iOS";
        else
            throw "Could not identify icon's platform from layout traits.";

        let iconName = icon.name;
        if (layoutTraits & LayoutTraits.macOS && layoutTraits & LayoutTraits.Fullscreen && IconsWithFullscreenVariants.includes(icon))
            iconName += "-fullscreen";

        let fileName = iconName;
        if (icon.type === "png")
            fileName = `${iconName}@${window.devicePixelRatio}x`;

        return [fileName, platform];
    }

};


class BackgroundTint extends LayoutNode
{

    constructor()
    {
        super(`<div class="background-tint"><div class="blur"></div><div class="tint"></div></div>`);
    }

}


const TenMinutes = 10 * 60;
const OneHour = 6 * TenMinutes;
const TenHours = 10 * OneHour;
const MinimumScrubberWidth = 120;
const ScrubberMargin = 5;

class TimeControl extends LayoutItem
{

    constructor(layoutDelegate)
    {
        super({
            element: `<div class="time-control"></div>`,
            layoutDelegate
        });

        this.elapsedTimeLabel = new TimeLabel(TimeLabel.Types.Elapsed);
        this.scrubber = new Slider("scrubber");
        this.remainingTimeLabel = new TimeLabel(TimeLabel.Types.Remaining);

        this.activityIndicator = new LayoutNode(`<div class="activity-indicator"></div>`);
        this.activityIndicator.width = 14;
        this.activityIndicator.height = 14;
        for (let segmentClassName of ["n", "ne", "e", "se", "s", "sw", "w", "nw"])
            this.activityIndicator.element.appendChild(document.createElement("div")).className = segmentClassName;

        this._duration = 0;
        this._currentTime = 0;
        this._loading = false;
    }

    // Public

    set duration(duration)
    {
        if (this._duration === duration)
            return;

        this._duration = duration;
        this.needsLayout = true;
    }

    set currentTime(currentTime)
    {
        if (this._currentTime === currentTime)
            return;

        this._currentTime = currentTime;
        this.needsLayout = true;
    }

    get loading()
    {
        return this._loading;
    }

    set loading(flag)
    {
        if (this._loading === flag)
            return;

        this._loading = flag;
        this.scrubber.disabled = flag;
        this.needsLayout = true;
    }

    get minimumWidth()
    {
        this._performIdealLayout();
        return MinimumScrubberWidth + ScrubberMargin + this.remainingTimeLabel.width;
    }

    get idealMinimumWidth()
    {
        this._performIdealLayout();
        return this.elapsedTimeLabel.width + ScrubberMargin + MinimumScrubberWidth + ScrubberMargin + this.remainingTimeLabel.width;
    }

    // Protected

    layout()
    {
        super.layout();
        this._performIdealLayout();

        if (this._loading)
            return;

        if (this.scrubber.width >= MinimumScrubberWidth) {
            this.elapsedTimeLabel.visible = true;
            return;
        }

        // We drop the elapsed time label if width is constrained and we can't guarantee
        // the scrubber minimum size otherwise.
        this.scrubber.x = 0;
        this.scrubber.width = this.width - ScrubberMargin - this.remainingTimeLabel.width;
        this.remainingTimeLabel.x = this.scrubber.x + this.scrubber.width + ScrubberMargin;
        this.elapsedTimeLabel.visible = false;
    }

    // Private

    _performIdealLayout()
    {
        if (this._loading)
            this.remainingTimeLabel.setValueWithNumberOfDigits(NaN, 4);
        else {
            const shouldShowZeroDurations = isNaN(this._duration) || this._duration === Number.POSITIVE_INFINITY;

            let numberOfDigitsForTimeLabels;
            if (this._duration < TenMinutes)
                numberOfDigitsForTimeLabels = 3;
            else if (shouldShowZeroDurations || this._duration < OneHour)
                numberOfDigitsForTimeLabels = 4;
            else if (this._duration < TenHours)
                numberOfDigitsForTimeLabels = 5;
            else
                numberOfDigitsForTimeLabels = 6;

            this.elapsedTimeLabel.setValueWithNumberOfDigits(shouldShowZeroDurations ? 0 : this._currentTime, numberOfDigitsForTimeLabels);
            this.remainingTimeLabel.setValueWithNumberOfDigits(shouldShowZeroDurations ? 0 : (this._currentTime - this._duration), numberOfDigitsForTimeLabels);
        }

        if (this._duration)
            this.scrubber.value = this._currentTime / this._duration;

        this.scrubber.x = (this._loading ? this.activityIndicator.width : this.elapsedTimeLabel.width) + ScrubberMargin;
        this.scrubber.width = this.width - this.scrubber.x - ScrubberMargin - this.remainingTimeLabel.width;
        this.remainingTimeLabel.x = this.scrubber.x + this.scrubber.width + ScrubberMargin;

        this.children = [this._loading ? this.activityIndicator : this.elapsedTimeLabel, this.scrubber, this.remainingTimeLabel];
    }

    updateScrubberLabel()
    {
        this.scrubber.inputAccessibleLabel = this.elapsedTimeLabel.value;
    }

}


const MinusSignWidthsForDigits = {
    3: 6,
    4: 5,
    5: 6,
    6: 5
};

const WidthsForDigits = {
    3: 27,
    4: 35,
    5: 46,
    6: 54
}

class TimeLabel extends LayoutNode
{

    constructor(type)
    {
        super(`<div role="text" class="time-label"></div>`);

        this._type = type;
        this.setValueWithNumberOfDigits(0, 4);
    }

    // Public

    get value()
    {
        return this._value;
    }

    setValueWithNumberOfDigits(value, numberOfDigits)
    {
        this._value = value;
        this._numberOfDigits = numberOfDigits;
        this.width = WidthsForDigits[this._numberOfDigits] + (this._type === TimeLabel.Types.Remaining && !isNaN(this._value) ? MinusSignWidthsForDigits[this._numberOfDigits] : 0);
        this.markDirtyProperty("value");
    }

    // Protected

    commitProperty(propertyName)
    {
        if (propertyName === "value") {
            this.element.textContent = this._formattedTime();
            const timeAsString = formattedStringForDuration(this.value);
            const ariaLabel = (this._type === TimeLabel.Types.Remaining) ? UIString("Remaining") : UIString("Elapsed");
            this.element.setAttribute("aria-label", `${ariaLabel}: ${timeAsString}`);
            if (this.parent instanceof TimeControl)
                this.parent.updateScrubberLabel();
        }
        else
            super.commitProperty(propertyName);
    }

    // Private

    _formattedTime()
    {
        if (isNaN(this._value))
            return "--:--";
        
        const time = formatTimeByUnit(this._value);

        let timeComponents;
        if (this._numberOfDigits == 3)
            timeComponents = [time.minutes, doubleDigits(time.seconds)];
        else if (this._numberOfDigits == 4)
            timeComponents = [doubleDigits(time.minutes), doubleDigits(time.seconds)];
        else if (this._numberOfDigits == 5)
            timeComponents = [time.hours, doubleDigits(time.minutes), doubleDigits(time.seconds)];
        else if (this._numberOfDigits == 6)
            timeComponents = [doubleDigits(time.hours), doubleDigits(time.minutes), doubleDigits(time.seconds)];

        return (this._type === TimeLabel.Types.Remaining ? "-" : "") + timeComponents.join(":");
    }

}

function doubleDigits(x)
{
    if (x < 10)
        return `0${x}`;
    return `${x}`;
}

TimeLabel.Types = {
    Elapsed: 0,
    Remaining: 1
};


class Slider extends LayoutNode
{

    constructor(cssClassName = "")
    {
        super(`<div class="slider ${cssClassName}"></div>`);

        this._container = new LayoutNode(`<div class="custom-slider"></div>`);
        this._track = new LayoutNode(`<div class="track fill"></div>`);
        this._primaryFill = new LayoutNode(`<div class="primary fill"></div>`);
        this._secondaryFill = new LayoutNode(`<div class="secondary fill"></div>`);
        this._knob = new LayoutNode(`<div class="knob"></div>`);
        this._container.children = [this._track, this._primaryFill, this._secondaryFill, this._knob];

        this._input = new LayoutNode(`<input type="range" min="0" max="1" step="0.001" />`);
        this._input.element.addEventListener("pointerdown", this);
        this._input.element.addEventListener("input", this);
        this._input.element.addEventListener("change", this);

        this.value = 0;
        this.height = 16;
        this.enabled = true;
        this.isActive = false;
        this._secondaryValue = 0;
        this._disabled = false;

        this.children = [this._container, this._input];
    }

    // Public

    set inputAccessibleLabel(timeValue)
    {
        this._input.element.setAttribute("aria-valuetext", formattedStringForDuration(timeValue));
    }

    get disabled()
    {
        return this._disabled;
    }

    set disabled(flag)
    {
        if (this._disabled === flag)
            return;

        this._disabled = flag;
        this.markDirtyProperty("disabled");
    }

    get value()
    {
        if (this._value !== undefined)
            return this._value;
        return parseFloat(this._input.element.value);
    }

    set value(value)
    {
        if (this.isActive)
            return;

        this._value = value;
        this.markDirtyProperty("value");
        this.needsLayout = true;
    }

    get secondaryValue()
    {
        return this._secondaryValue;
    }

    set secondaryValue(secondaryValue)
    {
        if (this._secondaryValue === secondaryValue)
            return;

        this._secondaryValue = secondaryValue;
        this.needsLayout = true;
    }

    // Protected

    handleEvent(event)
    {
        switch (event.type) {
        case "pointerdown":
            this._handlePointerdownEvent();
            break;
        case "pointerup":
            this._handlePointerupEvent();
            break;
        case "change":
        case "input":
            this._valueDidChange();
            break;
        }
    }

    commitProperty(propertyName)
    {
        switch (propertyName) {
        case "value":
            this._input.element.value = this._value;
            delete this._value;
            break;
        case "disabled":
            this.element.classList.toggle("disabled", this._disabled);
            break;
        default :
            super.commitProperty(propertyName);
            break;
        }
    }

    commit()
    {
        super.commit();

        const scrubberRadius = 4.5;
        const scrubberCenterX = scrubberRadius + Math.round((this.width - (scrubberRadius * 2)) * this.value);
        this._primaryFill.element.style.width = `${scrubberCenterX}px`;
        this._secondaryFill.element.style.left = `${scrubberCenterX}px`;
        this._secondaryFill.element.style.right = `${(1 - this._secondaryValue) * 100}%`;
        this._knob.element.style.left = `${scrubberCenterX}px`;
    }

    // Private

    _handlePointerdownEvent()
    {
        this._pointerupTarget = this._interactionEndTarget();
        this._pointerupTarget.addEventListener("pointerup", this, true);

        this._valueWillStartChanging();
    }

    _interactionEndTarget()
    {
        const mediaControls = this.parentOfType(MediaControls);
        return (!mediaControls || mediaControls instanceof MacOSInlineMediaControls) ? window : mediaControls.element;
    }

    _valueWillStartChanging()
    {
        // We should no longer cache the value since we'll be interacting with the <input>
        // so the value should be read back from it dynamically.
        delete this._value;

        if (this.uiDelegate && typeof this.uiDelegate.controlValueWillStartChanging === "function")
            this.uiDelegate.controlValueWillStartChanging(this);
        this.isActive = true;
        this.needsLayout = true;
    }

    _valueDidChange()
    {
        if (this.uiDelegate && typeof this.uiDelegate.controlValueDidChange === "function")
            this.uiDelegate.controlValueDidChange(this);

        this.needsLayout = true;
    }

    _valueDidStopChanging()
    {
        this.isActive = false;
        if (this.uiDelegate && typeof this.uiDelegate.controlValueDidStopChanging === "function")
            this.uiDelegate.controlValueDidStopChanging(this);

        this.needsLayout = true;
    }

    _handlePointerupEvent()
    {
        this._pointerupTarget.removeEventListener("pointerup", this, true);
        delete this._pointerupTarget;

        this._valueDidStopChanging();
    }
}


class Button extends LayoutItem
{

    constructor({ layoutDelegate = null, cssClassName = "", iconName = "" } = {})
    {
        super({
            element: "<button />",
            layoutDelegate
        });

        if (!!cssClassName)
            this.element.classList.add(cssClassName);

        this.style = Button.Styles.Bar;
        this.image = this.addChild(new LayoutNode(`<picture></picture>`));

        this._scaleFactor = 1;
        this._imageSource = null;
        this._iconName = "";

        if (!!iconName)
            this.iconName = iconName;

        this._enabled = true;

        if (GestureRecognizer.SupportsTouches)
            this._tapGestureRecognizer = new TapGestureRecognizer(this.element, this);
        else
            this.element.addEventListener("click", this);
    }

    // Public

    get enabled()
    {
        return this._enabled;
    }

    set enabled(flag)
    {
        if (this._enabled === flag)
            return;

        this._enabled = flag;
        if (this.layoutDelegate && typeof this.layoutDelegate.layout === "function")
            this.layoutDelegate.layout();
    }

    get iconName()
    {
        return this._iconName;
    }

    set iconName(iconName)
    {
        if (this._iconName === iconName)
            return;

        this._loadImage(iconName);
        this.element.setAttribute("aria-label", iconName.label);
    }

    get on()
    {
        return this.element.classList.contains("on");
    }

    set on(flag) {
        this.element.classList.toggle("on", flag);
    }

    get style()
    {
        return this._style;
    }

    set style(style)
    {
        if (style === this._style)
            return;

        this.element.classList.remove(this._style);
        this.element.classList.add(style);

        this._style = style;

        if (style === Button.Styles.Bar && this.children.length == 2)
            this.children[0].remove();
        else if (this.children.length == 1)
            this.addChild(new BackgroundTint, 0);
    }

    get scaleFactor()
    {
        return this._scaleFactor;
    }

    set scaleFactor(scaleFactor)
    {
        if (this._scaleFactor === scaleFactor)
            return;

        this._scaleFactor = scaleFactor;
        this._updateImageMetrics();
    }

    // Protected

    handleEvent(event)
    {
        if (event.target === this._imageSource) {
            if (event.type === "load")
                this._imageSourceDidLoad();
            else if (event.type === "error")
                console.error(`Button failed to load, iconName = ${this._iconName.name}, layoutTraits = ${this.layoutTraits}, src = ${this._imageSource.src}`);
        } else if (event.type === "click" && event.currentTarget === this.element)
            this._notifyDelegateOfActivation();
    }

    gestureRecognizerStateDidChange(recognizer)
    {
        if (this._tapGestureRecognizer === recognizer && recognizer.state === GestureRecognizer.States.Recognized)
            this._notifyDelegateOfActivation();
    }

    commitProperty(propertyName)
    {
        if (propertyName === "maskImage")
            this.image.element.style.webkitMaskImage = `url(${this._imageSource.src})`;
        else
            super.commitProperty(propertyName);
    }

    // Private

    _notifyDelegateOfActivation()
    {
        if (this._enabled && this.uiDelegate && typeof this.uiDelegate.buttonWasPressed === "function")
            this.uiDelegate.buttonWasPressed(this);
    }

    _loadImage(iconName)
    {
        if (this._imageSource)
            this._imageSource.removeEventListener("load", this);

        this._imageSource = iconService.imageForIconAndLayoutTraits(iconName, this.layoutTraits);

        this._iconName = iconName;

        if (this._imageSource.complete)
            this._updateImage();
        else {
            this._imageSource.addEventListener("load", this);
            this._imageSource.addEventListener("error", this);
        }
    }

    _imageSourceDidLoad()
    {
        this._imageSource.removeEventListener("load", this);
        this._updateImage();
    }

    _updateImage()
    {
        this.markDirtyProperty("maskImage");

        this._updateImageMetrics();
    }

    _updateImageMetrics()
    {
        let width = this._imageSource.width * this._scaleFactor;
        let height = this._imageSource.height * this._scaleFactor;

        if (this._iconName.type === "png" || this._iconName.type === "pdf") {
            width /= window.devicePixelRatio;
            height /= window.devicePixelRatio;
        }

        if (this.image.width === width && this.image.height === height)
            return;

        this.image.width = width;
        this.image.height = height;

        this.width = width;
        this.height = height;

        if (this.layoutDelegate)
            this.layoutDelegate.needsLayout = true;
    }

}

Button.Styles = {
    Bar: "bar",
    Corner: "corner",
    Center: "center",
    SmallCenter: "small-center"
};


class PlayPauseButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "play-pause",
            iconName: Icons.Play,
            layoutDelegate
        });

        if (this.layoutTraits & LayoutTraits.macOS && this.layoutTraits & LayoutTraits.Fullscreen)
            this.scaleFactor = 2;
    }

    // Public

    get playing()
    {
        return this.iconName === Icons.Pause;
    }

    set playing(flag)
    {
        if (this.playing === flag)
            return;

        this.iconName = flag ? Icons.Pause : Icons.Play;
    }

    // Protected

    commit()
    {
        super.commit();
        this.element.classList.toggle("paused", !this.playing);
    }

}


class SkipBackButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "skip-back",
            iconName: Icons.SkipBack,
            layoutDelegate
        });
    }

}


class SkipForwardButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "skip-forward",
            iconName: Icons.SkipForward,
            layoutDelegate
        });
    }

}


class MuteButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "mute",
            iconName: Icons.Volume,
            layoutDelegate
        });

        this._muted = false;
        this._usesRTLIconVariant = false;
    }

    // Public

    get muted()
    {
        return this._muted;
    }

    set muted(flag)
    {
        if (this._muted === flag)
            return;

        this._muted = flag;
        this.needsLayout = true;
    }

    set usesRTLIconVariant(flag)
    {
        if (this._usesRTLIconVariant === flag)
            return;

        this._usesRTLIconVariant = flag;
        this.needsLayout = true;
    }

    // Protected

    layout()
    {
        if (this._usesRTLIconVariant)
            this.iconName = this._muted ? Icons.VolumeMutedRTL : Icons.VolumeRTL;
        else
            this.iconName = this._muted ? Icons.VolumeMuted : Icons.Volume;
    }

}


class AirplayButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "airplay",
            iconName: Icons.Airplay,
            layoutDelegate
        });
    }

}


class PiPButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "pip",
            iconName: Icons.EnterPiP,
            layoutDelegate
        });
    }

}


class TracksButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "tracks",
            iconName: Icons.Tracks,
            layoutDelegate
        });
    }

}


class FullscreenButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "fullscreen",
            layoutDelegate
        });

        this.iconName = this.layoutTraits & LayoutTraits.Fullscreen ? Icons.ExitFullscreen : Icons.EnterFullscreen;
    }

}


class SeekButton extends Button
{

    constructor(options)
    {
        super(options);

        this.element.addEventListener("mousedown", this);
    }

    // Protected

    handleEvent(event)
    {
        if (event.type === "mousedown" && event.currentTarget === this.element)
            this._didStartPressing();
        else if (event.type === "mouseup")
            this._didStopPressing();
        else
            super.handleEvent(event);
    }

    // Private

    _didStartPressing()
    {
        const mediaControls = this.parentOfType(MediaControls);
        if (!mediaControls)
            return;

        this._mouseupTarget = mediaControls.element;
        this._mouseupTarget.addEventListener("mouseup", this, true);
        this._notifyDelegateOfPressingState(true);
    }

    _didStopPressing()
    {
        this._mouseupTarget.removeEventListener("mouseup", this, true);
        this._notifyDelegateOfPressingState(false);
    }

    _notifyDelegateOfPressingState(isPressed)
    {
        if (this._enabled && this.uiDelegate && typeof this.uiDelegate.buttonPressedStateDidChange === "function")
            this.uiDelegate.buttonPressedStateDidChange(this, isPressed);
    }

}


class RewindButton extends SeekButton
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "rewind",
            iconName: Icons.Rewind,
            layoutDelegate
        });
    }

}


class ForwardButton extends SeekButton
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "forward",
            iconName: Icons.Forward,
            layoutDelegate
        });
    }

}


class VolumeDownButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "volume-down",
            iconName: Icons.VolumeDown,
            layoutDelegate
        });
    }

}


class VolumeUpButton extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "volume-up",
            iconName: Icons.VolumeUp,
            layoutDelegate
        });
    }

}


class ButtonsContainer extends LayoutNode
{

    constructor({ children = [], leftMargin = 16, rightMargin = 16, buttonMargin = 16, cssClassName = "" } = {})
    {
        super(`<div class="buttons-container ${cssClassName}"></div>`);

        this.leftMargin = leftMargin;
        this.rightMargin = rightMargin;
        this.buttonMargin = buttonMargin;
        this.children = children;
    }

    // Public

    willRemoveChild(child)
    {
        super.willRemoveChild(child);

        // We reset properties that we may have overridden during layout to their default values.
        child.visible = true;
        child.x = 0;
    }

    didChangeChildren()
    {
        super.didChangeChildren();
        this.layout();
    }

    layout()
    {
        super.layout();

        let x = this.leftMargin;
        let numberOfVisibleButtons = 0;

        this._children.forEach(button => {
            button.visible = button.enabled && !button.dropped;
            if (!button.visible)
                return;

            button.x = x;
            x += button.width + this.buttonMargin;
            numberOfVisibleButtons++;
        });

        if (numberOfVisibleButtons)
            this.width = x - this.buttonMargin + this.rightMargin;
        else
            this.width = this.buttonMargin + this.rightMargin;
    }

}


class StatusLabel extends LayoutItem
{

    constructor(layoutDelegate)
    {
        super({
            element: `<div class="status-label"></div>`,
            layoutDelegate
        });

        this._text = "";
        this.minimumWidth = 120;
        this.idealMinimumWidth = this.minimumWidth;
    }

    // Public

    get text()
    {
        return this._text;
    }

    set text(text)
    {
        if (text === this._text)
            return;

        this._text = text;
        this.markDirtyProperty("text");

        if (this.layoutDelegate)
            this.layoutDelegate.needsLayout = true;
    }

    get enabled()
    {
        return this._text !== "";
    }

    // Protected

    commitProperty(propertyName)
    {
        if (propertyName === "text")
            this.element.textContent = this._text;
        else
            super.commitProperty(propertyName);
    }

}


class ControlsBar extends LayoutNode
{

    constructor(cssClassName = "")
    {
        super(`<div role="group" class="controls-bar ${cssClassName}"></div>`);
        this._translation = new DOMPoint;
        this._backgroundTint = this.addChild(new BackgroundTint);
    }

    // Public

    get children()
    {
        return super.children;
    }

    set children(children)
    {
        super.children = [this._backgroundTint].concat(children);
    }

    get translation()
    {
        return new DOMPoint(this._translation.x, this._translation.y);
    }

    set translation(point)
    {
        if (this._translation.x === point.x && this._translation.y === point.y)
            return;

        this._translation = new DOMPoint(point.x, point.y);
        this.markDirtyProperty("translation");
    }

    // Protected

    commitProperty(propertyName)
    {
        if (propertyName === "translation")
            this.element.style.transform = `translate(${this._translation.x}px, ${this._translation.y}px)`;
        else
            super.commitProperty(propertyName);
    }

}

class TracksPanel extends LayoutNode
{

    constructor()
    {
        super(`<div class="tracks-panel"></div>`);
        this._backgroundTint = new BackgroundTint;
        this._scrollableContainer = new LayoutNode(`<div class="scrollable-container"></div>`);
        this._rightX = 0;
        this._bottomY = 0;
        this._presented = false;
        
        this.children = [this._backgroundTint, this._scrollableContainer];
    }

    // Public

    get presented()
    {
        return this._presented;
    }

    presentInParent(node)
    {
        if (this._presented && this.parent === node)
            return;

        this._presented = true;

        this._scrollableContainer.children = this._childrenFromDataSource();

        node.addChild(this);

        this.element.removeEventListener("transitionend", this);
        this.element.classList.remove("fade-out");

        this._mousedownTarget().addEventListener("mousedown", this, true);
        window.addEventListener("keydown", this, true);

        this._focusedTrackNode = null;
    }

    hide()
    {
        if (!this._presented)
            return;

        this._presented = false;

        this._mousedownTarget().removeEventListener("mousedown", this, true);
        window.removeEventListener("keydown", this, true);

        this.element.addEventListener("transitionend", this);

        // Ensure a transition will indeed happen by starting it only on the next frame.
        window.requestAnimationFrame(() => { this.element.classList.add("fade-out"); });
    }

    get maxHeight()
    {
        return this._maxHeight;
    }

    set maxHeight(height)
    {
        if (this._maxHeight === height)
            return;

        this._maxHeight = height;
        this.markDirtyProperty("maxHeight")
    }

    get bottomY()
    {
        return this._bottomY;
    }

    set bottomY(bottomY)
    {
        if (this._bottomY === bottomY)
            return;

        this._bottomY = bottomY;
        this.markDirtyProperty("bottomY");
    }

    get rightX()
    {
        return this._rightX;
    }

    set rightX(x)
    {
        if (this._rightX === x)
            return;

        this._rightX = x;
        this.markDirtyProperty("rightX");
    }

    // Protected

    trackNodeSelectionAnimationDidEnd(trackNode)
    {
        if (this.uiDelegate && typeof this.uiDelegate.tracksPanelSelectionDidChange === "function")
            this.uiDelegate.tracksPanelSelectionDidChange(trackNode.index, trackNode.sectionIndex);
    }

    mouseMovedOverTrackNode(trackNode)
    {
        this._focusTrackNode(trackNode);
    }

    mouseExitedTrackNode(trackNode)
    {
        this._focusedTrackNode.element.blur();
        delete this._focusedTrackNode;
    }

    commitProperty(propertyName)
    {
        if (propertyName === "rightX")
            this.element.style.right = `${this._rightX}px`;
        else if (propertyName === "bottomY")
            this.element.style.bottom = `${this._bottomY}px`;
        else if (propertyName === "maxHeight") {
            this.element.style.maxHeight = `${this._maxHeight}px`;
            this._scrollableContainer.element.style.maxHeight = `${this._maxHeight}px`;
        } else
            super.commitProperty(propertyName);
    }

    handleEvent(event)
    {
        switch (event.type) {
        case "mousedown":
            this._handleMousedown(event);
            break;
        case "keydown":
            this._handleKeydown(event);
            break;
        case "transitionend":
            this.remove();
            break;
        }
    }

    // Private

    _mousedownTarget()
    {
        const mediaControls = this.parentOfType(MacOSFullscreenMediaControls);
        if (mediaControls)
            return mediaControls.element;
        return window;
    }

    _childrenFromDataSource()
    {
        const children = [];

        this._trackNodes = [];

        const dataSource = this.dataSource;
        if (!dataSource)
            return children;

        const numberOfSections = dataSource.tracksPanelNumberOfSections();
        if (numberOfSections === 0)
            return children;

        for (let sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex) {
            let sectionNode = new LayoutNode(`<section></section>`);
            sectionNode.addChild(new LayoutNode(`<h3>${dataSource.tracksPanelTitleForSection(sectionIndex)}</h3>`));

            let tracksListNode = sectionNode.addChild(new LayoutNode(`<ul></ul>`));
            let numberOfTracks = dataSource.tracksPanelNumberOfTracksInSection(sectionIndex);
            for (let trackIndex = 0; trackIndex < numberOfTracks; ++trackIndex) {
                let trackTitle = dataSource.tracksPanelTitleForTrackInSection(trackIndex, sectionIndex);
                let trackSelected = dataSource.tracksPanelIsTrackInSectionSelected(trackIndex, sectionIndex);
                let trackNode = tracksListNode.addChild(new TrackNode(trackIndex, sectionIndex, trackTitle, trackSelected, this));
                this._trackNodes.push(trackNode);
            }
            children.push(sectionNode);
        }

        return children;
    }

    _handleMousedown(event)
    {
        if (this._isPointInTracksPanel(new DOMPoint(event.clientX, event.clientY)))
            return;

        this._dismiss();

        event.preventDefault();
        event.stopPropagation();
    }

    _isPointInTracksPanel(point)
    {
        let ancestor = this.element.parentNode;
        while (ancestor && !(ancestor instanceof ShadowRoot))
            ancestor = ancestor.parentNode;

        if (!ancestor)
            ancestor = document;

        return this.element.contains(ancestor.elementFromPoint(point.x, point.y));
    }

    _handleKeydown(event)
    {
        switch (event.key) {
        case "Home":
        case "PageUp":
            this._focusFirstTrackNode();
            break;
        case "End":
        case "PageDown":
            this._focusLastTrackNode();
            break;
        case "ArrowDown":
            if (event.altKey || event.metaKey)
                this._focusLastTrackNode();
            else
                this._focusNextTrackNode();
            break;
        case "ArrowUp":
            if (event.altKey || event.metaKey)
                this._focusFirstTrackNode();
            else
                this._focusPreviousTrackNode();
            break;
        case " ":
        case "Enter":
            if (this._focusedTrackNode)
                this._focusedTrackNode.activate();
            break;
        case "Escape":
            this._dismiss();
            break;
        default:
            return;
        }

        // Ensure that we don't let the browser react to a key code we handled,
        // for instance scrolling the page if we handled an arrow key.
        event.preventDefault();
    }

    _dismiss()
    {
        if (this.parent && typeof this.parent.hideTracksPanel === "function")
            this.parent.hideTracksPanel();
    }

    _focusTrackNode(trackNode)
    {
        if (!trackNode || trackNode === this._focusedTrackNode)
            return;

        trackNode.element.focus();
        this._focusedTrackNode = trackNode;
    }

    _focusPreviousTrackNode()
    {
        const previousIndex = this._focusedTrackNode ? this._trackNodes.indexOf(this._focusedTrackNode) - 1 : this._trackNodes.length - 1;
        this._focusTrackNode(this._trackNodes[previousIndex]);
    }

    _focusNextTrackNode()
    {
        this._focusTrackNode(this._trackNodes[this._trackNodes.indexOf(this._focusedTrackNode) + 1]);
    }

    _focusFirstTrackNode()
    {
        this._focusTrackNode(this._trackNodes[0]);
    }

    _focusLastTrackNode()
    {
        this._focusTrackNode(this._trackNodes[this._trackNodes.length - 1]);
    }

}

class TrackNode extends LayoutNode
{

    constructor(index, sectionIndex, title, selected, panel)
    {
        super(`<li tabindex="0">${title}</li>`);

        this.index = index;
        this.sectionIndex = sectionIndex;
        this._panel = panel;
        this._selected = selected;

        if (selected)
            this.element.classList.add("selected");

        this.element.addEventListener("mousemove", this);
        this.element.addEventListener("mouseleave", this);
        this.element.addEventListener("click", this);
    }

    // Public

    activate()
    {
        this.element.addEventListener("animationend", this);
        this.element.classList.add("animated");
    }

    // Protected

    handleEvent(event)
    {
        switch (event.type) {
        case "mousemove":
            this._panel.mouseMovedOverTrackNode(this);
            break;
        case "mouseleave":
            this._panel.mouseExitedTrackNode(this);
            break;
        case "click":
            this.activate();
            break;
        case "animationend":
            this._animationDidEnd();
            break;
        }
    }

    // Private

    _animationDidEnd()
    {
        this.element.removeEventListener("animationend", this);
        this._panel.trackNodeSelectionAnimationDidEnd(this);
    }

}


const AutoHideDelayMS = 4000;

class AutoHideController
{

    constructor(mediaControls)
    {
        this._mediaControls = mediaControls;

        this._pointerIdentifiersPreventingAutoHide = new Set;
        this._pointerIdentifiersPreventingAutoHideForHover = new Set;

        if (GestureRecognizer.SupportsTouches)
            this._tapGestureRecognizer = new TapGestureRecognizer(this._mediaControls.element, this);

        this.autoHideDelay = AutoHideDelayMS;
    }

    // Public

    get fadesWhileIdle()
    {
        return this._fadesWhileIdle;
    }

    set fadesWhileIdle(flag)
    {
        if (this._fadesWhileIdle == flag)
            return;

        this._fadesWhileIdle = flag;

        if (flag) {
            this._mediaControls.element.addEventListener("pointermove", this);
            this._mediaControls.element.addEventListener("pointerdown", this);
            this._mediaControls.element.addEventListener("pointerup", this);
            this._mediaControls.element.addEventListener("pointerleave", this);
            this._mediaControls.element.addEventListener("pointerout", this);
        } else {
            this._mediaControls.element.removeEventListener("pointermove", this);
            this._mediaControls.element.removeEventListener("pointerdown", this);
            this._mediaControls.element.removeEventListener("pointerup", this);
            this._mediaControls.element.removeEventListener("pointerleave", this);
            this._mediaControls.element.removeEventListener("pointerout", this);
        }

        if (flag && !this._mediaControls.faded)
            this._resetAutoHideTimer(false);
        else if (!flag)
            this._mediaControls.faded = false;
    }

    // Protected

    handleEvent(event)
    {
        if (event.currentTarget !== this._mediaControls.element)
            return;

        if (event.type === "pointermove") {
            this._mediaControls.faded = false;
            this._resetAutoHideTimer(true);
            if (this._mediaControls.isPointInControls(new DOMPoint(event.clientX, event.clientY))) {
                this._pointerIdentifiersPreventingAutoHideForHover.add(event.pointerId);
                this._cancelNonEnforcedAutoHideTimer();
            } else {
                this._pointerIdentifiersPreventingAutoHideForHover.delete(event.pointerId);
                this._resetAutoHideTimer(true);
            }
        } else if (event.type === "pointerleave" && this._fadesWhileIdle && !this.hasSecondaryUIAttached && !this._enforceAutoHideTimer) {
            this._pointerIdentifiersPreventingAutoHide.delete(event.pointerId);
            this._pointerIdentifiersPreventingAutoHideForHover.delete(event.pointerId);

            // If the pointer is a mouse (supports hover), see if we can
            // immediately hide without waiting for the auto-hide timer.
            if (event.pointerType == "mouse")
                this._autoHideTimerFired();

            this._resetAutoHideTimer(true);
        }

        if (event.type === "pointerdown") {
            // Remember the current faded state so that we can determine,
            // if we recognize a tap, if it should fade the controls out.
            this._nextTapCanFadeControls = !this._mediaControls.faded;
            this._pointerIdentifiersPreventingAutoHide.add(event.pointerId);
            this._mediaControls.faded = false;
            this._cancelNonEnforcedAutoHideTimer();
        } else if (event.type === "pointerup") {
            this._pointerIdentifiersPreventingAutoHide.delete(event.pointerId);
            this._resetAutoHideTimer(true);
        }
    }

    gestureRecognizerStateDidChange(recognizer)
    {
        if (this._tapGestureRecognizer !== recognizer || recognizer.state !== GestureRecognizer.States.Recognized)
            return;

        this._mediaControls.faded = this._nextTapCanFadeControls && !this._mediaControls.isPointInControls(recognizer.locationInClient());
        delete this._nextTapCanFadeControls;
    }

    mediaControlsFadedStateDidChange()
    {
        if (this._mediaControls.faded)
            delete this._enforceAutoHideTimer;
        else
            this._resetAutoHideTimer(true);
    }

    mediaControlsBecameInvisible()
    {
        this._cancelNonEnforcedAutoHideTimer();
    }

    // Private

    _cancelNonEnforcedAutoHideTimer()
    {
        if (!this._enforceAutoHideTimer)
            this._cancelAutoHideTimer();
    }

    _cancelAutoHideTimer()
    {
        window.clearTimeout(this._autoHideTimer);
        delete this._autoHideTimer;
    }

    _resetAutoHideTimer(cancelable)
    {
        if (cancelable && this._enforceAutoHideTimer)
            return;

        this._cancelAutoHideTimer();

        if (cancelable)
            delete this._enforceAutoHideTimer;
        else
            this._enforceAutoHideTimer = true;

        this._autoHideTimer = window.setTimeout(this._autoHideTimerFired.bind(this), this.autoHideDelay);
    }

    _autoHideTimerFired()
    {
        const disableAutoHiding = this._pointerIdentifiersPreventingAutoHide.size || this._pointerIdentifiersPreventingAutoHideForHover.size;

        delete this._enforceAutoHideTimer;
        if (disableAutoHiding)
            return;

        this._cancelAutoHideTimer();
        this._mediaControls.faded = this._fadesWhileIdle && !this.hasSecondaryUIAttached;
    }

}


class MediaControls extends LayoutNode
{

    constructor({ width = 300, height = 150, layoutTraits = LayoutTraits.Unknown } = {})
    {
        super(`<div class="media-controls"></div>`);

        this._scaleFactor = 1;
        this._shouldCenterControlsVertically = false;

        this.width = width;
        this.height = height;
        this.layoutTraits = layoutTraits;

        this.playPauseButton = new PlayPauseButton(this);
        this.airplayButton = new AirplayButton(this);
        this.pipButton = new PiPButton(this);
        this.fullscreenButton = new FullscreenButton(this);
        this.muteButton = new MuteButton(this);
        this.tracksButton = new TracksButton(this);

        this.statusLabel = new StatusLabel(this);
        this.timeControl = new TimeControl(this);

        this.tracksPanel = new TracksPanel;

        this.bottomControlsBar = new ControlsBar("bottom");

        this.autoHideController = new AutoHideController(this);
        this.autoHideController.fadesWhileIdle = false;
        this.autoHideController.hasSecondaryUIAttached = false;

        this._placard = null;
        this.airplayPlacard = new AirplayPlacard(this);
        this.invalidPlacard = new InvalidPlacard(this);
        this.pipPlacard = new PiPPlacard(this);

        this.element.addEventListener("focusin", this);
        window.addEventListener("dragstart", this, true);
    }

    // Public

    get visible()
    {
        return super.visible;
    }

    set visible(flag)
    {
        if (this.visible === flag)
            return;

        // If we just got made visible again, let's fade the controls in.
        if (flag && !this.visible)
            this.faded = false;
        else if (!flag)
            this.autoHideController.mediaControlsBecameInvisible();

        super.visible = flag;

        if (flag)
            this.layout();

        if (this.delegate && typeof this.delegate.mediaControlsVisibilityDidChange === "function")
            this.delegate.mediaControlsVisibilityDidChange();
    }

    get faded()
    {
        return !!this._faded;
    }

    set faded(flag)
    {
        if (this._faded === flag)
            return;

        this._faded = flag;
        this.markDirtyProperty("faded");

        this.autoHideController.mediaControlsFadedStateDidChange();
        if (this.delegate && typeof this.delegate.mediaControlsFadedStateDidChange === "function")
            this.delegate.mediaControlsFadedStateDidChange();
    }

    get usesLTRUserInterfaceLayoutDirection()
    {
        return this.element.classList.contains("uses-ltr-user-interface-layout-direction");
    }

    set usesLTRUserInterfaceLayoutDirection(flag)
    {
        this.needsLayout = this.usesLTRUserInterfaceLayoutDirection !== flag;
        this.element.classList.toggle("uses-ltr-user-interface-layout-direction", flag);
    }

    get scaleFactor()
    {
        return this._scaleFactor;
    }

    set scaleFactor(scaleFactor)
    {
        if (this._scaleFactor === scaleFactor)
            return;

        this._scaleFactor = scaleFactor;
        this.markDirtyProperty("scaleFactor");
    }

    get shouldCenterControlsVertically()
    {
        return this._shouldCenterControlsVertically;
    }

    set shouldCenterControlsVertically(flag)
    {
        if (this._shouldCenterControlsVertically === flag)
            return;

        this._shouldCenterControlsVertically = flag;
        this.markDirtyProperty("scaleFactor");
    }

    get placard()
    {
        return this._placard;
    }

    set placard(placard)
    {
        if (this._placard === placard)
            return;

        this._placard = placard;
        this.layout();
    }

    placardPreventsControlsBarDisplay()
    {
        return this._placard && this._placard !== this.airplayPlacard;
    }

    showTracksPanel()
    {
        this.element.classList.add("shows-tracks-panel");

        this.tracksButton.on = true;
        this.tracksButton.element.blur();
        this.autoHideController.hasSecondaryUIAttached = true;
        this.tracksPanel.presentInParent(this);

        const controlsBounds = this.element.getBoundingClientRect();
        const controlsBarBounds = this.bottomControlsBar.element.getBoundingClientRect();
        const tracksButtonBounds = this.tracksButton.element.getBoundingClientRect();
        this.tracksPanel.rightX = this.width - (tracksButtonBounds.right - controlsBounds.left);
        this.tracksPanel.bottomY = this.height - (controlsBarBounds.top - controlsBounds.top) + 1;
        this.tracksPanel.maxHeight = this.height - this.tracksPanel.bottomY - 10;
    }

    hideTracksPanel()
    {
        this.element.classList.remove("shows-tracks-panel");

        let shouldFadeControlsBar = true;
        if (window.event instanceof MouseEvent)
            shouldFadeControlsBar = !this.isPointInControls(new DOMPoint(event.clientX, event.clientY), true);

        this.tracksButton.on = false;
        this.tracksButton.element.focus();
        this.autoHideController.hasSecondaryUIAttached = false;
        this.faded = this.autoHideController.fadesWhileIdle && shouldFadeControlsBar;
        this.tracksPanel.hide();
    }

    fadeIn()
    {
        this.element.classList.add("fade-in");
    }

    isPointInControls(point, includeContainer)
    {
        let ancestor = this.element.parentNode;
        while (ancestor && !(ancestor instanceof ShadowRoot))
            ancestor = ancestor.parentNode;

        const shadowRoot = ancestor;
        if (!shadowRoot)
            return false;

        const tappedElement = shadowRoot.elementFromPoint(point.x, point.y);

        if (includeContainer && this.element === tappedElement)
            return true;

        return this.children.some(child => child.element.contains(tappedElement));
    }

    // Protected

    handleEvent(event)
    {
        if (event.type === "focusin" && event.currentTarget === this.element)
            this.faded = false;
        else if (event.type === "dragstart" && this.isPointInControls(new DOMPoint(event.clientX, event.clientY)))
            event.preventDefault();
    }

    layout()
    {
        super.layout();

        if (this._placard) {
            this._placard.width = this.width;
            this._placard.height = this.height;
        }
    }

    commitProperty(propertyName)
    {
        if (propertyName === "scaleFactor") {
            const zoom = 1 / this._scaleFactor;
            // We want to maintain the controls at a constant device height. To do so, we invert the page scale
            // factor using a scale transform when scaling down, when the result will not appear pixelated and
            // where the CSS zoom property produces incorrect text rendering due to enforcing the minimum font
            // size. When we would end up scaling up, which would yield pixelation, we use the CSS zoom property
            // which will not run into the font size issue.
            if (zoom < 1) {
                this.element.style.transform = `scale(${zoom})`;
                this.element.style.removeProperty("zoom");
            } else {
                this.element.style.zoom = zoom;
                this.element.style.removeProperty("transform");
            }
            // We also want to optionally center them vertically compared to their container.
            this.element.style.top = this._shouldCenterControlsVertically ? `${(this.height / 2) * (zoom - 1)}px` : "auto"; 
        } else if (propertyName === "faded")
            this.element.classList.toggle("faded", this.faded);
        else
            super.commitProperty(propertyName);
    }

}


class BackgroundClickDelegateNotifier
{

    constructor(mediaControls)
    {
        this._mediaControls = mediaControls;
        mediaControls.element.addEventListener("mousedown", this);
        mediaControls.element.addEventListener("click", this);
    }

    // Protected

    handleEvent(event)
    {
        const mediaControls = this._mediaControls;
        if (event.currentTarget !== mediaControls.element)
            return;

        // Only notify that the background was clicked when the "mousedown" event
        // was also received, which wouldn't happen if the "mousedown" event caused
        // the tracks panel to be hidden, unless we're in fullscreen in which case
        // we can simply check that the panel is not currently presented.
        if (event.type === "mousedown" && !mediaControls.tracksPanel.presented)
            this._receivedMousedown = true;
        else if (event.type === "click") {
            if (this._receivedMousedown && event.target === mediaControls.element && mediaControls.delegate && typeof mediaControls.delegate.macOSControlsBackgroundWasClicked === "function")
                mediaControls.delegate.macOSControlsBackgroundWasClicked();
            delete this._receivedMousedown
        }
    }

}


const InsideMargin = 6; // Minimum margin to guarantee around all controls, this constant needs to stay in sync with the --inline-controls-inside-margin CSS variable.
const BottomControlsBarHeight = 31; // This constant needs to stay in sync with the --inline-controls-bar-height CSS variable.

class InlineMediaControls extends MediaControls
{

    constructor(options)
    {
        super(options);

        this.element.classList.add("inline");

        this.skipBackButton = new SkipBackButton(this);
        this.skipForwardButton = new SkipForwardButton(this);

        this.topLeftControlsBar = new ControlsBar("top-left");
        this._topLeftControlsBarContainer = this.topLeftControlsBar.addChild(new ButtonsContainer);

        this.topRightControlsBar = new ControlsBar("top-right");
        this._topRightControlsBarContainer = this.topRightControlsBar.addChild(new ButtonsContainer);

        this.leftContainer = new ButtonsContainer({ cssClassName: "left" });
        this.rightContainer = new ButtonsContainer({ cssClassName: "right" });

        this._shouldUseAudioLayout = false;
        this._shouldUseSingleBarLayout = false;
        this.showsStartButton = false;
        this._updateBottomControlsBarLabel();
    }

    // Public

    set shouldUseAudioLayout(flag)
    {
        if (this._shouldUseAudioLayout === flag)
            return;

        this._shouldUseAudioLayout = flag;
        this.element.classList.toggle("audio", flag);
        this.needsLayout = true;
        this._updateBottomControlsBarLabel();
    }

    set shouldUseSingleBarLayout(flag)
    {
        if (this._shouldUseSingleBarLayout === flag)
            return;

        this._shouldUseSingleBarLayout = flag;
        this.needsLayout = true;
    }

    get showsStartButton()
    {
        return !!this._showsStartButton;
    }

    set showsStartButton(flag)
    {
        if (this._showsStartButton === flag)
            return;

        this._showsStartButton = flag;
        this.layout();
    }

    // Protected

    layout()
    {
        super.layout();

        const children = [];

        if (this.placard) {
            children.push(this.placard);
            if (this.placardPreventsControlsBarDisplay()) {
                this.children = children;
                return;
            }
        }

        if (!this.visible) {
            this.children = children;
            return;
        }

        // The controls might be too small to allow showing anything at all.
        if (!this._shouldUseAudioLayout && (this.width < MinimumSizeToShowAnyControl || this.height < MinimumSizeToShowAnyControl)) {
            this.children = children;
            return;
        }

        // If we should show the start button, then only show that button.
        if (this._showsStartButton) {
            this.playPauseButton.style = this.width <= MaximumSizeToShowSmallProminentControl || this.height <= MaximumSizeToShowSmallProminentControl ? Button.Styles.SmallCenter : Button.Styles.Center;
            this.children = [this.playPauseButton];
            return;
        }

        if (!this.bottomControlsBar)
            return;

        // Ensure the tracks panel is a child if it were presented.
        if (this.tracksPanel.presented)
            children.push(this.tracksPanel);

        // Update the top left controls bar.
        this._topLeftControlsBarContainer.children = this._topLeftContainerButtons();
        this._topLeftControlsBarContainer.layout();
        this.topLeftControlsBar.width = this._topLeftControlsBarContainer.width;
        this.topLeftControlsBar.visible = this._topLeftControlsBarContainer.children.some(button => button.visible);

        // Compute the visible size for the controls bar.
        this.bottomControlsBar.width = this._shouldUseAudioLayout ? this.width : (this.width - 2 * InsideMargin);

        // Compute the absolute minimum width to display the center control (status label or time control).
        const centerControl = this.statusLabel.enabled ? this.statusLabel : this.timeControl;
        let minimumCenterControlWidth = centerControl.minimumWidth;

        // Worst case scenario is that we can't fit the center control with the required margins. In this case,
        // we need to make the play/pause button display as a corner button.
        const minimumControlsBarWidthForCenterControl = minimumCenterControlWidth + this.leftContainer.leftMargin + this.rightContainer.rightMargin;
        if (this.bottomControlsBar.width < minimumControlsBarWidthForCenterControl) {
            this.playPauseButton.style = Button.Styles.Corner;
            if (!this._shouldUseSingleBarLayout && this.height >= 82) {
                children.push(this.topLeftControlsBar);
                this._addTopRightBarWithMuteButtonToChildren(children);
            }
            this.children = children.concat(this.playPauseButton);
            return;
        }

        // Now allow the minimum center element to display with fewer constraints.
        minimumCenterControlWidth = centerControl.idealMinimumWidth;

        // Iterate through controls to see if we need to drop any of them. Reset all default states before we proceed.
        this.bottomControlsBar.visible = true;
        this.playPauseButton.style = Button.Styles.Bar;
        this.leftContainer.children = this._leftContainerButtons();
        this.rightContainer.children = this._rightContainerButtons();
        this.rightContainer.children.concat(this.leftContainer.children).forEach(button => delete button.dropped);
        this.muteButton.style = this.preferredMuteButtonStyle;
        this.muteButton.usesRTLIconVariant = !this.usesLTRUserInterfaceLayoutDirection;

        for (let button of this._droppableButtons()) {
            // If the button is not enabled, we can skip it.
            if (!button.enabled)
                continue;

            // Ensure button containers are laid out with latest constraints.
            this.leftContainer.layout();
            this.rightContainer.layout();

            // Nothing left to do if the combined width of both containers and the time control is shorter than the available width.
            if (this.leftContainer.width + minimumCenterControlWidth + this.rightContainer.width < this.bottomControlsBar.width)
                break;

            // This button must now be dropped.
            button.dropped = true;
        }

        // Update layouts once more.
        this.leftContainer.layout();
        this.rightContainer.layout();

        const widthLeftOfTimeControl = this.leftContainer.children.length > 0 ? this.leftContainer.width : this.leftContainer.leftMargin;
        const widthRightOfTimeControl = this.rightContainer.children.length > 0 ? this.rightContainer.width : this.rightContainer.rightMargin;
        centerControl.x = widthLeftOfTimeControl;
        centerControl.width = this.bottomControlsBar.width - widthLeftOfTimeControl - widthRightOfTimeControl;
        centerControl.layout();

        // Add visible children.
        const controlsBarChildren = [];
        if (this.leftContainer.children.length)
            controlsBarChildren.push(this.leftContainer);
        controlsBarChildren.push(centerControl);
        if (this.rightContainer.children.length) {
            controlsBarChildren.push(this.rightContainer);
            this.rightContainer.x = this.bottomControlsBar.width - this.rightContainer.width;
        }

        // Ensure we position the bottom controls bar at the bottom of the frame, accounting for
        // the inside margin, unless this would yield a position outside of the frame.
        this.bottomControlsBar.y = Math.max(0, this.height - BottomControlsBarHeight - InsideMargin);

        this.bottomControlsBar.children = controlsBarChildren;
        if (!this._shouldUseAudioLayout && !this._shouldUseSingleBarLayout)
            children.push(this.topLeftControlsBar);
        children.push(this.bottomControlsBar);
        if (this.muteButton.style === Button.Styles.Corner || (this.muteButton.dropped && !this._shouldUseAudioLayout && !this._shouldUseSingleBarLayout))
            this._addTopRightBarWithMuteButtonToChildren(children);
        this.children = children;
    }

    commitProperty(propertyName)
    {
        // We override the default behavior of the "visible" property, which usually means the node
        // will not be displayed if false, but we want to allow placards to be visible, even when
        // controls are supposed to be hidden.
        if (propertyName !== "visible")
            super.commitProperty(propertyName);
    }

    get preferredMuteButtonStyle()
    {
        return (this._shouldUseAudioLayout || this._shouldUseSingleBarLayout) ? Button.Styles.Bar : Button.Styles.Corner;
    }

    // Private

    _updateBottomControlsBarLabel()
    {
        this.bottomControlsBar.element.setAttribute("aria-label", this._shouldUseAudioLayout ? UIString("Audio Controls") : UIString("Video Controls"));
    }
    
    _topLeftContainerButtons()
    {
        if (this._shouldUseSingleBarLayout)
            return [];
        if (this.usesLTRUserInterfaceLayoutDirection)
            return [this.fullscreenButton, this.pipButton];
        return [this.pipButton, this.fullscreenButton];
    }

    _leftContainerButtons()
    {
        return [this.skipBackButton, this.playPauseButton, this.skipForwardButton];
    }

    _rightContainerButtons()
    {
        if (this._shouldUseAudioLayout)
            return [this.muteButton, this.airplayButton];

        if (this._shouldUseSingleBarLayout)
            return [this.muteButton, this.airplayButton, this.pipButton, this.tracksButton, this.fullscreenButton];

        const buttons = [];
        if (this.preferredMuteButtonStyle === Button.Styles.Bar)
            buttons.push(this.muteButton);
        buttons.push(this.airplayButton, this.tracksButton);
        return buttons;
    }

    _droppableButtons()
    {
        if (this._shouldUseSingleBarLayout)
            return [this.skipForwardButton, this.skipBackButton, this.airplayButton, this.tracksButton, this.pipButton, this.fullscreenButton, this.muteButton];

        const buttons = [this.skipForwardButton, this.skipBackButton, this.airplayButton, this.tracksButton];
        if (this.preferredMuteButtonStyle === Button.Styles.Bar)
            buttons.push(this.muteButton);
        return buttons;
    }

    _addTopRightBarWithMuteButtonToChildren(children)
    {
        if (!this.muteButton.enabled)
            return;

        delete this.muteButton.dropped;
        this.muteButton.style = Button.Styles.Bar;
        this.muteButton.usesRTLIconVariant = !this.usesLTRUserInterfaceLayoutDirection;
        this._topRightControlsBarContainer.children = [this.muteButton];
        this._topRightControlsBarContainer.layout();
        this.topRightControlsBar.width = this._topRightControlsBarContainer.width;
        children.push(this.topRightControlsBar);
    }

}


class IOSInlineMediaControls extends InlineMediaControls
{

    constructor(options = {})
    {
        options.layoutTraits = LayoutTraits.iOS;

        super(options);

        this.element.classList.add("ios");

        this._updateGestureRecognizers();
    }

    // Public

    get showsStartButton()
    {
        return super.showsStartButton;
    }

    set showsStartButton(flag)
    {
        super.showsStartButton = flag;
        this._updateGestureRecognizers();
    }

    get visible()
    {
        return super.visible;
    }

    set visible(flag)
    {
        super.visible = flag;
        this._updateGestureRecognizers();
    }

    // Protected

    gestureRecognizerStateDidChange(recognizer)
    {
        if (recognizer === this._pinchGestureRecognizer)
            this._pinchGestureRecognizerStateDidChange(recognizer);
        else if (recognizer === this._tapGestureRecognizer)
            this._tapGestureRecognizerStateDidChange(recognizer);
    }

    // Private

    _updateGestureRecognizers()
    {
        const shouldListenToPinches = this.visible;
        const shouldListenToTaps = this.visible && this.showsStartButton;

        if (shouldListenToPinches && !this._pinchGestureRecognizer)
            this._pinchGestureRecognizer = new PinchGestureRecognizer(this.element, this);
        else if (!shouldListenToPinches && this._pinchGestureRecognizer) {
            this._pinchGestureRecognizer.enabled = false;
            delete this._pinchGestureRecognizer;
        }

        if (shouldListenToTaps && !this._tapGestureRecognizer)
            this._tapGestureRecognizer = new TapGestureRecognizer(this.element, this);
        else if (!shouldListenToTaps && this._tapGestureRecognizer) {
            this._tapGestureRecognizer.enabled = false;
            delete this._tapGestureRecognizer;
        }
    }

    _pinchGestureRecognizerStateDidChange(recognizer)
    {
        console.assert(this.visible);
        if (recognizer.state !== GestureRecognizer.States.Ended && recognizer.state !== GestureRecognizer.States.Changed)
            return;

        if (recognizer.scale > IOSInlineMediaControls.MinimumScaleToEnterFullscreen && this.delegate && typeof this.delegate.iOSInlineMediaControlsRecognizedPinchInGesture === "function")
            this.delegate.iOSInlineMediaControlsRecognizedPinchInGesture();
    }

    _tapGestureRecognizerStateDidChange(recognizer)
    {
        console.assert(this.visible && this.showsStartButton);
        if (recognizer.state === GestureRecognizer.States.Recognized && this.delegate && typeof this.delegate.iOSInlineMediaControlsRecognizedTapGesture === "function")
            this.delegate.iOSInlineMediaControlsRecognizedTapGesture();
    }

}

IOSInlineMediaControls.MinimumScaleToEnterFullscreen = 1.5;


const MinimumHeightToShowVolumeSlider = 136;

class MacOSInlineMediaControls extends InlineMediaControls
{

    constructor(options = {})
    {
        options.layoutTraits = LayoutTraits.macOS;

        super(options);

        this.element.classList.add("mac");

        this._backgroundClickDelegateNotifier = new BackgroundClickDelegateNotifier(this);

        this.volumeSlider = new Slider("volume");
        this.volumeSlider.width = 60;

        this._volumeSliderContainer = new LayoutNode(`<div class="volume-slider-container"></div>`);
        this._volumeSliderContainer.children = [new BackgroundTint, this.volumeSlider];

        // Wire up events to display the volume slider.
        this.muteButton.element.addEventListener("mouseenter", this);
        this.muteButton.element.addEventListener("mouseleave", this);
        this._volumeSliderContainer.element.addEventListener("mouseleave", this);
    }

    // Protected

    layout()
    {
        super.layout();

        if (!this._volumeSliderContainer)
            return;

        this._volumeSliderContainer.x = this.rightContainer.x + this.muteButton.x;
        this._volumeSliderContainer.y = this.bottomControlsBar.y - BottomControlsBarHeight - InsideMargin;
    }

    get preferredMuteButtonStyle()
    {
        return (this.height >= MinimumHeightToShowVolumeSlider) ? Button.Styles.Bar : super.preferredMuteButtonStyle;
    }

    handleEvent(event)
    {
        if (event.type === "mouseenter" && event.currentTarget === this.muteButton.element) {
            if (this.muteButton.parent === this.rightContainer)
                this.addChild(this._volumeSliderContainer);
        } else if (event.type === "mouseleave" && (event.currentTarget === this.muteButton.element || event.currentTarget === this._volumeSliderContainer.element)) {
            if (!this._volumeSliderContainer.element.contains(event.relatedTarget))
                this._volumeSliderContainer.remove();
        } else
            super.handleEvent(event);
    }

}


const ButtonMarginForThreeButtonsOrLess = 24;
const ButtonMarginForFourButtons = 16;
const ButtonMarginForFiveButtons = 12;
const FullscreenTimeControlWidth = 448;

class MacOSFullscreenMediaControls extends MediaControls
{

    constructor(options = {})
    {
        options.layoutTraits = LayoutTraits.macOS | LayoutTraits.Fullscreen;

        super(options);

        this.element.classList.add("mac");
        this.element.classList.add("fullscreen");

        // Set up fullscreen-specific buttons.
        this.volumeDownButton = new VolumeDownButton(this);
        this.volumeUpButton = new VolumeUpButton(this);
        this.rewindButton = new RewindButton(this);
        this.forwardButton = new ForwardButton(this);
        this.fullscreenButton.isFullscreen = true;

        this.volumeSlider = new Slider("volume");
        this.volumeSlider.width = 60;

        this._leftContainer = new ButtonsContainer({
            children: this._volumeControlsForCurrentDirection(),
            cssClassName: "left",
            leftMargin: 12,
            rightMargin: 0,
            buttonMargin: 6
        });

        this._centerContainer = new ButtonsContainer({
            children: [this.rewindButton, this.playPauseButton, this.forwardButton],
            cssClassName: "center",
            leftMargin: 27,
            rightMargin: 27,
            buttonMargin: 27
        });

        this._rightContainer = new ButtonsContainer({
            children: [this.airplayButton, this.pipButton, this.tracksButton, this.fullscreenButton],
            cssClassName: "right",
            leftMargin: 12,
            rightMargin: 12
        });

        this.bottomControlsBar.children = [this._leftContainer, this._centerContainer, this._rightContainer];

        this.bottomControlsBar.element.addEventListener("mousedown", this);

        this._backgroundClickDelegateNotifier = new BackgroundClickDelegateNotifier(this);
    }

    // Protected

    handleEvent(event)
    {
        if (event.type === "mousedown" && event.currentTarget === this.bottomControlsBar.element)
            this._handleMousedown(event);
        else if (event.type === "mousemove" && event.currentTarget === this.element)
            this._handleMousemove(event);
        else if (event.type === "mouseup" && event.currentTarget === this.element)
            this._handleMouseup(event);
        else
            super.handleEvent(event);
    }

    layout()
    {
        super.layout();

        const children = [];

        if (this.placard) {
            children.push(this.placard);
            if (this.placardPreventsControlsBarDisplay()) {
                this.children = children;
                return;
            }
        }

        children.push(this.bottomControlsBar);

        if (!this._rightContainer)
            return;

        const numberOfEnabledButtons = this._rightContainer.children.filter(button => button.enabled).length;

        let buttonMargin = ButtonMarginForFiveButtons;
        if (numberOfEnabledButtons === 4)
            buttonMargin = ButtonMarginForFourButtons;
        else if (numberOfEnabledButtons <= 3)
            buttonMargin = ButtonMarginForThreeButtonsOrLess;

        this._rightContainer.buttonMargin = buttonMargin;

        this._leftContainer.visible = this.muteButton.enabled;
        this._leftContainer.children = this._volumeControlsForCurrentDirection();

        this._leftContainer.layout();
        this._centerContainer.layout();
        this._rightContainer.layout();

        if (this.statusLabel.enabled && this.statusLabel.parent !== this.bottomControlsBar) {
            this.timeControl.remove();
            this.bottomControlsBar.addChild(this.statusLabel);
        } else if (!this.statusLabel.enabled && this.timeControl.parent !== this.bottomControlsBar) {
            this.statusLabel.remove();
            this.bottomControlsBar.addChild(this.timeControl);
            this.timeControl.width = FullscreenTimeControlWidth;
        }

        this.children = children;
    }

    // Private

    _volumeControlsForCurrentDirection()
    {
        return this.usesLTRUserInterfaceLayoutDirection ? [this.volumeDownButton, this.volumeSlider, this.volumeUpButton] : [this.volumeUpButton, this.volumeSlider, this.volumeDownButton];
    }

    _handleMousedown(event)
    {
        // We don't allow dragging when the interaction is initiated on an interactive element. 
        if (event.target.localName === "button" || event.target.parentNode.localName === "button" || event.target.localName === "input")
            return;

        event.preventDefault();
        event.stopPropagation();

        this._lastDragPoint = this._pointForEvent(event);

        this.element.addEventListener("mousemove", this, true);
        this.element.addEventListener("mouseup", this, true);
    }

    _handleMousemove(event)
    {
        event.preventDefault();

        const currentDragPoint = this._pointForEvent(event);

        this.bottomControlsBar.translation = new DOMPoint(
            this.bottomControlsBar.translation.x + currentDragPoint.x - this._lastDragPoint.x,
            this.bottomControlsBar.translation.y + currentDragPoint.y - this._lastDragPoint.y
        );

        this._lastDragPoint = currentDragPoint;
    }

    _handleMouseup(event)
    {
        event.preventDefault();

        delete this._lastDragPoint;

        this.element.removeEventListener("mousemove", this, true);
        this.element.removeEventListener("mouseup", this, true);
    }

    _pointForEvent(event)
    {
        return new DOMPoint(event.clientX, event.clientY);
    }

}


const MinHeightToDisplayDescription = 100;
const MinHeightToDisplayTitle = 40;

class Placard extends LayoutItem
{

    constructor({ iconName = null, title = "", description = "", width = 400, height = 300, layoutDelegate = null } = {})
    {
        super({
            element: `<div class="placard"></div>`,
            layoutDelegate
        });

        this._container = this.addChild(new LayoutNode(`<div class="container"></div>`));
        
        if (iconName) {
            this._icon = new Button(this);
            this._icon.iconName = iconName;
            this._icon.element.disabled = true;
        }

        if (!!title)
            this._titleNode = new LayoutNode(`<div class="title">${title}</div>`);

        if (!!description)
            this._descriptionNode = new LayoutNode(`<div class="description">${description}</div>`);

        this.minDimensionToDisplayIcon = 170;

        this.width = width;
        this.height = height;
    }

    // Protected

    layout()
    {
        super.layout();

        const children = [];

        if (this._icon && this.width >= this.minDimensionToDisplayIcon && this.height >= this.minDimensionToDisplayIcon)
            children.push(this._icon);

        if (this._titleNode && this.height >= MinHeightToDisplayTitle)
            children.push(this._titleNode);

        if (this._descriptionNode && this.height >= MinHeightToDisplayDescription)
            children.push(this._descriptionNode);

        this._container.children = children;
    }
    
    set description(description)
    {
        this._descriptionNode = !!description ? new LayoutNode(`<div class="description">${description}</div>`) : null;
        this.needsLayout = true;
    }

}


class AirplayPlacard extends Placard
{

    constructor(layoutDelegate)
    {
        super({
            iconName: Icons.AirplayPlacard,
            title: UIString("AirPlay"),
            description: UIString("This video is playing on the TV."),
            layoutDelegate
        });
    }

}


class InvalidPlacard extends Placard
{

    constructor(layoutDelegate)
    {
        super({
            iconName: Icons.InvalidPlacard,
            layoutDelegate
        });

        this.minDimensionToDisplayIcon = 50;
    }

}


class PiPPlacard extends Placard
{

    constructor(layoutDelegate)
    {
        super({
            iconName: Icons.PiPPlacard,
            description: UIString("This video is playing in picture in picture."),
            layoutDelegate
        });
    }

}


class CompactActivityIndicator extends Button
{

    constructor(layoutDelegate)
    {
        super({
            cssClassName: "compact-activity-indicator",
            iconName: Icons.SpinnerCompact,
            layoutDelegate
        });
    }

    // Public

    show()
    {
        const classList = this.element.classList;
        classList.add("spins");
        classList.remove("fades-out");
    }

    hide()
    {
        const classList = this.element.classList;
        if (!classList.contains("spins") || classList.contains("fades-out"))
            return;

        classList.add("fades-out");
        this.image.element.addEventListener("animationend", event => {
            if (event.animationName !== "compact-activity-indicator-fades-out")
                return;
            classList.remove("spins");
            classList.remove("fades-out");
        }, { once: true });
    }
    
}


class CompactMediaControls extends LayoutNode
{

    constructor({ width = 320, height = 240 } = {})
    {
        super(`<div class="compact media-controls"></div>`);

        this._state = CompactMediaControls.States.Paused;
        this._scaleFactor = 1;
        this._shouldCenterControlsVertically = false;

        this.layoutTraits = LayoutTraits.Compact;

        this.playButton = new Button({
            cssClassName: "play",
            iconName: Icons.PlayCompact,
            layoutDelegate: this
        });

        this.invalidButton = new Button({
            cssClassName: "invalid",
            iconName: Icons.InvalidCompact,
            layoutDelegate: this
        });

        this.activityIndicator = new CompactActivityIndicator(this);

        this.width = width;
        this.height = height;
    }

    // Public

    get scaleFactor()
    {
        return this._scaleFactor;
    }

    set scaleFactor(scaleFactor)
    {
        if (this._scaleFactor === scaleFactor)
            return;

        this._scaleFactor = scaleFactor;
        this.markDirtyProperty("scaleFactor");
    }

    get shouldCenterControlsVertically()
    {
        return this._shouldCenterControlsVertically;
    }

    set shouldCenterControlsVertically(flag)
    {
        if (this._shouldCenterControlsVertically === flag)
            return;

        this._shouldCenterControlsVertically = flag;
        this.markDirtyProperty("scaleFactor");
    }

    get state()
    {
        return this._state;
    }

    set state(state)
    {
        if (this._state === state)
            return;

        this._state = state;
        this.layout();
    }

    // Protected

    layout()
    {
        super.layout();

        switch (this._state) {
        case CompactMediaControls.States.Paused:
            this.children = [this.playButton];
            break;
        case CompactMediaControls.States.Pending:
            this.children = [this.activityIndicator];
            this.activityIndicator.show();
            break;
        case CompactMediaControls.States.Invalid:
            this.children = [this.invalidButton];
            break;
        }
    }

    commitProperty(propertyName)
    {
        if (propertyName !== "scaleFactor") {
            super.commitProperty(propertyName);
            return;
        }

        const zoom = 1 / this._scaleFactor;
        // We want to maintain the controls at a constant device height. To do so, we invert the page scale
        // factor using a scale transform when scaling down, when the result will not appear pixelated and
        // where the CSS zoom property produces incorrect text rendering due to enforcing the minimum font
        // size. When we would end up scaling up, which would yield pixelation, we use the CSS zoom property
        // which will not run into the font size issue.
        if (zoom < 1) {
            this.element.style.transform = `scale(${zoom})`;
            this.element.style.removeProperty("zoom");
        } else {
            this.element.style.zoom = zoom;
            this.element.style.removeProperty("transform");
        }
        // We also want to optionally center them vertically compared to their container.
        this.element.style.top = this._shouldCenterControlsVertically ? `${(this.height / 2) * (zoom - 1)}px` : "auto"; 
    }

}

CompactMediaControls.States = {
    Paused: "paused",
    Pending: "pending",
    Invalid: "invalid"
};


class MediaControllerSupport
{

    constructor(mediaController)
    {
        this.mediaController = mediaController;

        this.enable();
    }

    // Public

    enable()
    {
        for (let eventType of this.mediaEvents)
            this.mediaController.media.addEventListener(eventType, this, true);

        for (let tracks of this.tracksToMonitor) {
            for (let eventType of ["change", "addtrack", "removetrack"])
                tracks.addEventListener(eventType, this);
        }

        if (!this.control)
            return;

        this.control.uiDelegate = this;
        this.syncControl();
    }

    disable()
    {
        for (let eventType of this.mediaEvents)
            this.mediaController.media.removeEventListener(eventType, this, true);

        for (let tracks of this.tracksToMonitor) {
            for (let eventType of ["change", "addtrack", "removetrack"])
                tracks.removeEventListener(eventType, this);
        }

        if (this.control)
            this.control.uiDelegate = null;
    }

    // Protected

    get control()
    {
        // Implemented by subclasses.
    }

    get mediaEvents()
    {
        // Implemented by subclasses.
        return [];
    }

    get tracksToMonitor()
    {
        // Implemented by subclasses.
        return [];
    }

    buttonWasPressed(control)
    {
        // Implemented by subclasses.
    }

    controlsUserVisibilityDidChange()
    {
        // Implement by subclasses.
    }

    handleEvent(event)
    {
        // Implemented by subclasses.
        if (this.control)
            this.syncControl();
    }

    syncControl()
    {
        // Implemented by subclasses.
    }
}


class AirplaySupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.airplayButton;
    }

    get mediaEvents()
    {
        return ["webkitplaybacktargetavailabilitychanged", "webkitcurrentplaybacktargetiswirelesschanged"];
    }

    enable()
    {
        if (this._shouldBeEnabled())
            super.enable();
    }

    buttonWasPressed(control)
    {
        this.mediaController.media.webkitShowPlaybackTargetPicker();
    }

    controlsUserVisibilityDidChange()
    {
        if (this._shouldBeEnabled())
            this.enable();
        else
            this.disable();
    }

    handleEvent(event)
    {
        if (event.type === "webkitplaybacktargetavailabilitychanged")
            this._routesAvailable = event.availability === "available";

        super.handleEvent(event);
    }

    syncControl()
    {
        this.control.enabled = !!this._routesAvailable;
        this.control.on = this.mediaController.media.webkitCurrentPlaybackTargetIsWireless;
        this.mediaController.controls.muteButton.enabled = !this.control.on;
    }

    // Private

    _shouldBeEnabled()
    {
        if (!this.mediaController.hasPlayed)
            return false;

        const controls = this.mediaController.controls;
        return controls.visible && !controls.faded;
    }

}


class AudioSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls;
    }

    get mediaEvents()
    {
        return ["loadedmetadata", "error"];
    }

    get tracksToMonitor()
    {
        return [this.mediaController.media.videoTracks];
    }

    syncControl()
    {
        this.control.shouldUseAudioLayout = this.mediaController.isAudio;
        if (this.mediaController.mediaDocumentController)
            this.mediaController.mediaDocumentController.layout();
    }

}


class ControlsVisibilitySupport extends MediaControllerSupport
{

    constructor(mediaController)
    {
        super(mediaController);

        this._updateControls();
    }

    // Protected

    enable()
    {
        super.enable();
        this._updateControls();
    }

    disable()
    {
        super.disable();
        this.mediaController.controls.autoHideController.fadesWhileIdle = false;
    }

    get mediaEvents()
    {
        return ["loadedmetadata", "play", "pause", "webkitcurrentplaybacktargetiswirelesschanged", this.mediaController.fullscreenChangeEventType];
    }

    get tracksToMonitor()
    {
        return [this.mediaController.media.videoTracks];
    }

    handleEvent()
    {
        this._updateControls();
    }

    // Private

    _updateControls()
    {
        const media = this.mediaController.media;
        const isVideo = media instanceof HTMLVideoElement && media.videoTracks.length > 0;
        this.mediaController.controls.autoHideController.fadesWhileIdle = isVideo ? !media.paused && !media.webkitCurrentPlaybackTargetIsWireless : false;
    }

}


class FullscreenSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.fullscreenButton;
    }

    get mediaEvents()
    {
        return ["loadedmetadata"];
    }

    get tracksToMonitor()
    {
        return [this.mediaController.media.videoTracks];
    }

    buttonWasPressed(control)
    {
        const media = this.mediaController.media;
        if (this.mediaController.isFullscreen)
            media.webkitExitFullscreen();
        else
            media.webkitEnterFullscreen();
    }

    syncControl()
    {
        const control = this.control;
        const media = this.mediaController.media;
        control.enabled = !this.mediaController.isAudio && (media.readyState < HTMLMediaElement.HAVE_METADATA || media.webkitSupportsFullscreen);
        control.isFullScreen = this.mediaController.isFullscreen;
    }

}


class MuteSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.muteButton;
    }

    get mediaEvents()
    {
        return ["volumechange"];
    }

    buttonWasPressed(control)
    {
        const media = this.mediaController.media;
        media.muted = !media.muted;
    }

    syncControl()
    {
        this.control.muted = this.mediaController.media.muted;
    }

}


const PiPMode = "picture-in-picture";
const InlineMode = "inline";

class PiPSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.pipButton;
    }

    get mediaEvents()
    {
        return ["loadedmetadata", "error", "webkitpresentationmodechanged", "webkitcurrentplaybacktargetiswirelesschanged"];
    }

    get tracksToMonitor()
    {
        return [this.mediaController.media.videoTracks];
    }

    buttonWasPressed(control)
    {
        const media = this.mediaController.media;
        if (!document.pictureInPictureEnabled) {
            media.webkitSetPresentationMode(media.webkitPresentationMode === PiPMode ? InlineMode : PiPMode);
            return;
        }

        if (!document.pictureInPictureElement)
            media.requestPictureInPicture();
        else
            document.exitPictureInPicture();
    }

    syncControl()
    {
        const media = this.mediaController.media;
        if (media.webkitSupportsPresentationMode)
            this.control.enabled = !this.mediaController.isAudio && media.webkitSupportsPresentationMode(PiPMode) && !media.webkitCurrentPlaybackTargetIsWireless;
        else
            this.control.enabled = false;
    }

}


class PlacardSupport extends MediaControllerSupport
{

    constructor(mediaController)
    {
        super(mediaController);
        this._updatePlacard();
    }

    // Protected

    get mediaEvents()
    {
        return ["loadstart", "error", "webkitpresentationmodechanged", "webkitcurrentplaybacktargetiswirelesschanged"];
    }

    handleEvent(event)
    {
        this._updatePlacard();
    }

    enable()
    {
        super.enable();
        this._isDisabled = false;
        this._updatePlacard();
    }

    disable()
    {
        // Never disable the plackard, just remeber whether the placard should be visible or not
        this._isDisabled = true;
        this._updatePlacard();
    }

    // Private

    _updatePlacard()
    {
        const controls = this.mediaController.controls;
        const media = this.mediaController.media;

        let placard = null;
        if (media.webkitPresentationMode === "picture-in-picture")
            placard = controls.pipPlacard;
        else if (media.webkitCurrentPlaybackTargetIsWireless) {
            this._updateAirPlayPlacard();
            placard = controls.airplayPlacard;
        } else if (!this._isDisabled && media instanceof HTMLVideoElement && media.error !== null && media.played.length === 0)
            placard = controls.invalidPlacard;

        controls.placard = placard;
    }
    
    _updateAirPlayPlacard()
    {
        var deviceName = "";
        
        if (!this.mediaController.host)
            return;
        
        switch(this.mediaController.host.externalDeviceType) {
            case 'airplay':
                deviceName = UIString("This video is playing on “%s”.", escapeHTML(this.mediaController.host.externalDeviceDisplayName) || UIString("Apple TV"));
                break;
            case 'tvout':
                deviceName = UIString("This video is playing on the TV.");
                break;
        }
        this.mediaController.controls.airplayPlacard.description = deviceName;
    }

}

function escapeHTML(unsafeString)
{
    var div = document.createElement("div");
    div.textContent = unsafeString;
    return div.innerHTML;
}


class PlaybackSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.playPauseButton;
    }

    get mediaEvents()
    {
        return ["play", "pause"];
    }

    buttonWasPressed(control)
    {
        this.mediaController.togglePlayback();
    }

    syncControl()
    {
        this.control.playing = !this.mediaController.media.paused;
    }

}


class ScrubbingSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.timeControl.scrubber;
    }

    get mediaEvents()
    {
        return ["progress"];
    }

    controlValueWillStartChanging(control)
    {
        const media = this.mediaController.media;
        const isPaused = media.paused;
        if (!isPaused)
            media.pause();

        this._wasPausedWhenScrubbingStarted = isPaused;
    }

    controlValueDidChange(control)
    {
        const media = this.mediaController.media;
        media.fastSeek(control.value * media.duration);
    }

    controlValueDidStopChanging(control)
    {
        if (!this._wasPausedWhenScrubbingStarted)
            this.mediaController.media.play();

        delete this._wasPausedWhenScrubbingStarted;
    }

    syncControl()
    {
        const media = this.mediaController.media;
        if (isNaN(media.duration))
            return;

        let buffered = 0;
        for (let i = 0, count = media.buffered.length; i < count; ++i)
            buffered = Math.max(media.buffered.end(i), buffered);

        this.control.secondaryValue = buffered / media.duration;
    }

}


class SeekSupport extends MediaControllerSupport
{

    // Protected

    get mediaEvents()
    {
        return ["durationchange"];
    }

    get multiplier()
    {
        // Implemented by subclasses.
    }

    buttonPressedStateDidChange(control, isPressed)
    {
        if (isPressed)
            this._startSeeking();
        else
            this._stopSeeking();
    }

    syncControl()
    {
        this.control.enabled = this.mediaController.media.duration !== Number.POSITIVE_INFINITY;
    }

    // Private

    _startSeeking()
    {
        const media = this.mediaController.media;
        const isPaused = media.paused;
        if (isPaused)
            media.play();

        this._wasPausedWhenSeekingStarted = isPaused;
        this._interval = window.setInterval(this._seek.bind(this), SeekSupport.SeekDelay);
        this._seek();
    }

    _stopSeeking()
    {
        const media = this.mediaController.media;
        media.playbackRate = media.defaultPlaybackRate;
        if (this._wasPausedWhenSeekingStarted)
            media.pause();
        if (this._interval)
            window.clearInterval(this._interval);
    }

    _seek()
    {
        const media = this.mediaController.media;
        media.playbackRate = Math.min(SeekSupport.MaximumSeekRate, Math.abs(media.playbackRate * 2)) * this.multiplier;
    }

}

SeekSupport.MaximumSeekRate = 8;
SeekSupport.SeekDelay = 1500;


class SeekBackwardSupport extends SeekSupport
{

    get control()
    {
        return this.mediaController.controls.rewindButton;
    }

    get multiplier()
    {
        return -1;
    }

}


class SeekForwardSupport extends SeekSupport
{

    get control()
    {
        return this.mediaController.controls.forwardButton;
    }

    get multiplier()
    {
        return 1;
    }

}


class SkipBackSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.skipBackButton;
    }

    get mediaEvents()
    {
        return ["durationchange"];
    }

    buttonWasPressed(control)
    {
        const media = this.mediaController.media;
        media.currentTime = Math.max(media.currentTime - SkipSeconds, media.seekable.start(0));
    }

    syncControl()
    {
        this.control.enabled = this.mediaController.media.duration !== Number.POSITIVE_INFINITY;
    }

}


class SkipForwardSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.skipForwardButton;
    }

    get mediaEvents()
    {
        return ["durationchange"];
    }

    buttonWasPressed(control)
    {
        const media = this.mediaController.media;
        media.currentTime = Math.min(media.currentTime + SkipSeconds, media.seekable.end(0));
    }

    syncControl()
    {
        this.control.enabled = this.mediaController.media.duration !== Number.POSITIVE_INFINITY;
    }

}


class StartSupport extends MediaControllerSupport
{

    constructor(mediaController)
    {
        super(mediaController);

        this._updateShowsStartButton();
    }

    // Protected

    get mediaEvents()
    {
        return ["loadedmetadata", "play", "error", this.mediaController.fullscreenChangeEventType];
    }

    enable()
    {
        super.enable();

        this._updateShowsStartButton();
    }

    buttonWasPressed(control)
    {
        this.mediaController.media.play();
    }

    handleEvent(event)
    {
        super.handleEvent(event);

        this._updateShowsStartButton();
    }

    // Private

    _updateShowsStartButton()
    {
        this.mediaController.controls.showsStartButton = this._shouldShowStartButton();
    }

    _shouldShowStartButton()
    {
        const media = this.mediaController.media;
        const host = this.mediaController.host;

        if (host && host.shouldForceControlsDisplay)
            return true;

        if (this.mediaController.hasPlayed || media.played.length)
            return false;

        if (!media.paused)
            return false;

        if (media.autoplay)
            return false;

        if (media instanceof HTMLAudioElement)
            return false;

        if (this.mediaController.isFullscreen)
            return false;

        if (media.error)
            return false;

        if (!media.controls && host && host.allowsInlineMediaPlayback)
            return false;

        return true;
    }

}


class StatusSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.statusLabel;
    }

    get mediaEvents()
    {
        return ["durationchange", "loadstart", "error", "abort", "suspend", "stalled", "waiting", "playing", "emptied", "loadedmetadata", "loadeddata", "canplay", "canplaythrough"];
    }

    syncControl()
    {
        const media = this.mediaController.media;
        const isLiveBroadcast = media.duration === Number.POSITIVE_INFINITY;
        const canPlayThrough = media.readyState === HTMLMediaElement.HAVE_ENOUGH_DATA && !media.error;

        if (!!media.error)
            this.control.text = UIString("Error");
        else if (isLiveBroadcast && media.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA)
            this.control.text = UIString("Live Broadcast");
        else
            this.control.text = "";

        this.mediaController.controls.timeControl.loading = !media.played.length && !canPlayThrough && media.networkState === HTMLMediaElement.NETWORK_LOADING;
    }

}


class TimeControlSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.timeControl;
    }

    get mediaEvents()
    {
        return ["timeupdate", "durationchange"];
    }

    syncControl()
    {
        const media = this.mediaController.media;
        this.control.currentTime = media.currentTime;
        this.control.duration = media.duration;
    }

}


class TracksSupport extends MediaControllerSupport
{

    constructor(mediaController)
    {
        super(mediaController);

        if (!this.control)
            return;

        this.mediaController.controls.tracksPanel.dataSource = this;
        this.mediaController.controls.tracksPanel.uiDelegate = this;
    }

    // Protected

    get control()
    {
        return this.mediaController.controls.tracksButton;
    }

    get mediaEvents()
    {
        return ["loadedmetadata"];
    }

    get tracksToMonitor()
    {
        return [this.mediaController.media.audioTracks, this.mediaController.media.textTracks];
    }

    buttonWasPressed(control)
    {
        this.mediaController.controls.showTracksPanel();
    }

    tracksPanelNumberOfSections()
    {
        let numberOfSections = 0;
        if (this._canPickAudioTracks())
            numberOfSections++;
        if (this._canPickTextTracks())
            numberOfSections++;
        return numberOfSections;
    }

    tracksPanelTitleForSection(sectionIndex)
    {
        if (sectionIndex == 0 && this._canPickAudioTracks())
            return UIString("Audio");
        return UIString("Subtitles");
    }

    tracksPanelNumberOfTracksInSection(sectionIndex)
    {
        if (sectionIndex == 0 && this._canPickAudioTracks())
            return this._audioTracks().length;
        return this._textTracks().length;
    }

    tracksPanelTitleForTrackInSection(trackIndex, sectionIndex)
    {
        let track;
        if (sectionIndex == 0 && this._canPickAudioTracks())
            track = this._audioTracks()[trackIndex];
        else
            track = this._textTracks()[trackIndex];

        if (this.mediaController.host)
            return this.mediaController.host.displayNameForTrack(track);
        return track.label;
    }

    tracksPanelIsTrackInSectionSelected(trackIndex, sectionIndex)
    {
        if (sectionIndex == 0 && this._canPickAudioTracks())
            return this._audioTracks()[trackIndex].enabled;

        const textTracks = this._textTracks();
        const trackItem = textTracks[trackIndex];
        const host = this.mediaController.host;
        const trackIsShowing = track => track.mode === "showing";
        const allTracksDisabled = !textTracks.some(trackIsShowing);
        const usesAutomaticTrack = host ? (host.captionDisplayMode === "automatic" && allTracksDisabled) : false;

        if (allTracksDisabled && host && trackItem === host.captionMenuOffItem && (host.captionDisplayMode === "forced-only" || host.captionDisplayMode === "manual"))
            return true;
        if (host && trackItem === host.captionMenuAutomaticItem && usesAutomaticTrack)
            return true;
        return !usesAutomaticTrack && trackIsShowing(trackItem);
    }

    tracksPanelSelectionDidChange(trackIndex, sectionIndex)
    {
        if (sectionIndex == 0 && this._canPickAudioTracks())
            this._audioTracks().forEach((audioTrack, index) => audioTrack.enabled = index === trackIndex);
        else if (this.mediaController.host) {
            this._textTracks().forEach(textTrack => textTrack.mode = "disabled");
            this.mediaController.host.setSelectedTextTrack(this._textTracks()[trackIndex]);
        } else
            this._textTracks().forEach((textTrack, index) => textTrack.mode = index === trackIndex ? "showing" : "disabled");

        this.mediaController.controls.hideTracksPanel();
    }

    syncControl()
    {
        this.control.enabled = (this.mediaController.layoutTraits & LayoutTraits.macOS) && (this._canPickAudioTracks() || this._canPickTextTracks());
    }

    // Private

    _textTracks()
    {
        return this._sortedTrackList(this.mediaController.media.textTracks);
    }

    _audioTracks()
    {
        return this._sortedTrackList(this.mediaController.media.audioTracks);
    }

    _canPickAudioTracks()
    {
        const audioTracks = this._audioTracks();
        return audioTracks && audioTracks.length > 1;
    }

    _canPickTextTracks()
    {
        const textTracks = this._textTracks();
        return textTracks && textTracks.length > 0;
    }

    _sortedTrackList(tracks)
    {
        return Array.from(this.mediaController.host ? this.mediaController.host.sortedTrackListForMenu(tracks) : tracks);
    }

}


class VolumeDownSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.volumeDownButton;
    }

    buttonWasPressed(control)
    {
        this.mediaController.media.volume = 0;
    }

}


class VolumeSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.volumeSlider;
    }

    get mediaEvents()
    {
        return ["volumechange"];
    }

    controlValueWillStartChanging(control)
    {
        this._volumeBeforeChange = this.mediaController.media.volume;
        this.mediaController.media.muted = false;
    }

    controlValueDidChange(control)
    {
        this.mediaController.media.volume = (control.value === 0 && this._volumeBeforeChange > 0) ? this._volumeBeforeChange : control.value;
        this.mediaController.media.muted = control.value === 0;
    }

    syncControl()
    {
        const media = this.mediaController.media;
        this.control.value = media.muted ? 0 : media.volume;
    }

}


class VolumeUpSupport extends MediaControllerSupport
{

    // Protected

    get control()
    {
        return this.mediaController.controls.volumeUpButton;
    }

    buttonWasPressed(control)
    {
        this.mediaController.media.volume = 1;
    }

}


class MediaDocumentController
{

    constructor(mediaController)
    {
        this.mediaController = mediaController;

        // Force the controls to look like we're loading an audio file by default.
        mediaController.controls.shouldUseAudioLayout = true;
        mediaController.controls.timeControl.loading = true;

        this._hasDeterminedMediaType = false;

        const media = mediaController.media;
        media.classList.add("media-document");
        media.classList.add("audio");

        let deviceType = window.navigator.platform;
        if (deviceType == "MacIntel")
            deviceType = GestureRecognizer.SupportsTouches ? "ipad" : "mac";

        media.classList.add(deviceType);

        media.addEventListener("error", this);
        media.addEventListener("play", this);
    }

    // Public

    layout()
    {
        if (!this._hasDeterminedMediaType)
            return;

        scheduler.scheduleLayout(() => {
            const media = this.mediaController.media;
            const isInvalid = media.error !== null && media.played.length === 0;
            const useVideoLayout = isInvalid || (media.readyState >= HTMLMediaElement.HAVE_METADATA && !this.mediaController.isAudio);

            const classList = media.classList;
            classList.toggle("invalid", isInvalid);
            classList.toggle("video", useVideoLayout);
            classList.toggle("audio", !useVideoLayout);
        });
    }

    // Protected

    handleEvent(event)
    {
        event.currentTarget.removeEventListener(event.type, this);

        if (event.type === "play" || event.type === "error") {
            this._hasDeterminedMediaType = true;
            this.layout();
        }
    }

}


class CompactMediaControlsSupport extends MediaControllerSupport
{

    // Protected

    get mediaEvents()
    {
        return ["pause", "error"];
    }

    handleEvent(event)
    {
        switch (event.type) {
        case "pause":
            this.mediaController.controls.state = CompactMediaControls.States.Paused;
            break;
        case "error":
            this.mediaController.controls.state = CompactMediaControls.States.Invalid;
            break;
        }
    }

    enable()
    {
        super.enable();
        
        for (let button of this._buttons())
            button.uiDelegate = this;
    }

    disable()
    {
        super.disable();
        
        for (let button of this._buttons())
            button.uiDelegate = null;
    }

    buttonWasPressed(button)
    {
        if (button === this.mediaController.controls.playButton) {
            this.mediaController.media.play();
            this.mediaController.controls.state = CompactMediaControls.States.Pending;
        } else if (button === this.mediaController.controls.activityIndicator) {
            this.mediaController.media.pause();
            this.mediaController.controls.state = CompactMediaControls.States.Paused;
        }
    }

    // Private

    _buttons()
    {
        return [this.mediaController.controls.playButton, this.mediaController.controls.activityIndicator];
    }

}


class MediaController
{

    constructor(shadowRoot, media, host)
    {
        this.shadowRoot = shadowRoot;
        this.media = media;
        this.host = host;

        this.fullscreenChangeEventType = media.webkitSupportsPresentationMode ? "webkitpresentationmodechanged" : "webkitfullscreenchange";

        this.hasPlayed = false;

        this.container = shadowRoot.appendChild(document.createElement("div"));
        this.container.className = "media-controls-container";

        this._updateControlsIfNeeded();
        this._usesLTRUserInterfaceLayoutDirection = false;

        if (host) {
            host.controlsDependOnPageScaleFactor = this.layoutTraits & LayoutTraits.iOS;
            this.container.insertBefore(host.textTrackContainer, this.controls.element);
            if (host.isInMediaDocument)
                this.mediaDocumentController = new MediaDocumentController(this);
        }

        scheduler.flushScheduledLayoutCallbacks();

        shadowRoot.addEventListener("resize", this);

        media.videoTracks.addEventListener("addtrack", this);
        media.videoTracks.addEventListener("removetrack", this);

        media.addEventListener("play", this);
        media.addEventListener(this.fullscreenChangeEventType, this);

        window.addEventListener("keydown", this);

        new MutationObserver(this._updateControlsAvailability.bind(this)).observe(this.media, { attributes: true, attributeFilter: ["controls"] });
    }

    // Public

    get isAudio()
    {
        if (this.media instanceof HTMLAudioElement)
            return true;

        if (this.host && !this.host.isInMediaDocument && this.media instanceof HTMLVideoElement)
            return false;

        if (this.media.readyState < HTMLMediaElement.HAVE_METADATA)
            return false;

        if (this.media.videoWidth || this.media.videoHeight)
            return false;

        return !this.media.videoTracks.length;
    }

    get isYouTubeEmbedWithTitle()
    {
        const url = new URL(this.media.ownerDocument.defaultView.location.href);
        return url.href.includes("youtube.com/embed/") && url.searchParams.get("showinfo") !== "0";
    }

    get isFullscreen()
    {
        return this.media.webkitSupportsPresentationMode ? this.media.webkitPresentationMode === "fullscreen" : this.media.webkitDisplayingFullscreen;
    }

    get layoutTraits()
    {
        if (this.host && this.host.compactMode)
            return LayoutTraits.Compact;

        let traits = window.isIOSFamily ? LayoutTraits.iOS : LayoutTraits.macOS;
        if (this.isFullscreen)
            return traits | LayoutTraits.Fullscreen;
        return traits;
    }

    togglePlayback()
    {
        if (this.media.paused)
            this.media.play().catch(e => {});
        else
            this.media.pause();
    }

    // Protected

    set pageScaleFactor(pageScaleFactor)
    {
        this.controls.scaleFactor = pageScaleFactor;
        this._updateControlsSize();
    }

    set usesLTRUserInterfaceLayoutDirection(flag)
    {
        if (this._usesLTRUserInterfaceLayoutDirection === flag)
            return;

        this._usesLTRUserInterfaceLayoutDirection = flag;
        this.controls.usesLTRUserInterfaceLayoutDirection = flag;
    }

    mediaControlsVisibilityDidChange()
    {
        this._controlsUserVisibilityDidChange();
    }

    mediaControlsFadedStateDidChange()
    {
        this._controlsUserVisibilityDidChange();
        this._updateTextTracksClassList();
    }

    macOSControlsBackgroundWasClicked()
    {
        // Toggle playback when clicking on the video but not on any controls on macOS.
        if (this.media.controls)
            this.togglePlayback();
    }

    iOSInlineMediaControlsRecognizedTapGesture()
    {
        // Initiate playback when tapping anywhere over the video when showsStartButton is true.
        if (this.media.controls)
            this.media.play();
    }

    iOSInlineMediaControlsRecognizedPinchInGesture()
    {
        this.media.webkitEnterFullscreen();
    }

    handleEvent(event)
    {
        if (event instanceof TrackEvent && event.currentTarget === this.media.videoTracks)
            this._updateControlsIfNeeded();
        else if (event.type === "resize" && event.currentTarget === this.shadowRoot) {
            this._updateControlsIfNeeded();
            // We must immediately perform layouts so that we don't lag behind the media layout size.
            scheduler.flushScheduledLayoutCallbacks();
        } else if (event.currentTarget === this.media) {
            if (event.type === "play")
                this.hasPlayed = true;
            this._updateControlsIfNeeded();
            this._updateControlsAvailability();
        } else if (event.type === "keydown" && this.isFullscreen && event.key === " ") {
            this.togglePlayback();
            event.preventDefault();
        }
    }

    // Private

    _supportingObjectClasses()
    {
        if (this.layoutTraits & LayoutTraits.Compact)
            return [CompactMediaControlsSupport];

        return [AirplaySupport, AudioSupport, ControlsVisibilitySupport, FullscreenSupport, MuteSupport, PiPSupport, PlacardSupport, PlaybackSupport, ScrubbingSupport, SeekBackwardSupport, SeekForwardSupport, SkipBackSupport, SkipForwardSupport, StartSupport, StatusSupport, TimeControlSupport, TracksSupport, VolumeSupport, VolumeDownSupport, VolumeUpSupport];
    }

    _updateControlsIfNeeded()
    {
        const layoutTraits = this.layoutTraits;
        const previousControls = this.controls;
        const ControlsClass = this._controlsClassForLayoutTraits(layoutTraits);
        if (previousControls && previousControls.constructor === ControlsClass) {
            this._updateTextTracksClassList();
            this._updateControlsSize();
            return;
        }

        // Before we reset the .controls property, we need to disable the previous
        // supporting objects so we don't leak.
        if (this._supportingObjects) {
            for (let supportingObject of this._supportingObjects)
                supportingObject.disable();
        }

        this.controls = new ControlsClass;
        this.controls.delegate = this;

        if (this.controls.autoHideController && this.shadowRoot.host && this.shadowRoot.host.dataset.autoHideDelay)
            this.controls.autoHideController.autoHideDelay = this.shadowRoot.host.dataset.autoHideDelay;

        if (previousControls) {
            this.controls.fadeIn();
            this.container.replaceChild(this.controls.element, previousControls.element);
            this.controls.usesLTRUserInterfaceLayoutDirection = previousControls.usesLTRUserInterfaceLayoutDirection;
        } else
            this.container.appendChild(this.controls.element);

        this._updateTextTracksClassList();
        this._updateControlsSize();

        this._supportingObjects = this._supportingObjectClasses().map(SupportClass => new SupportClass(this), this);

        this.controls.shouldUseSingleBarLayout = this.controls instanceof InlineMediaControls && this.isYouTubeEmbedWithTitle;

        this._updateControlsAvailability();
    }

    _updateControlsSize()
    {
        // To compute the bounds of the controls, we need to account for the computed transform applied
        // to the media element, and apply the inverted transform to the bounds computed on the container
        // element in the shadow root, which is naturally sized to match the metrics of its host,
        // excluding borders.

        // First, we traverse the node hierarchy up from the media element to compute the effective
        // transform matrix applied to the media element.
        let node = this.media;
        let transform = new DOMMatrix;
        while (node && node instanceof HTMLElement) {
            transform = transform.multiply(new DOMMatrix(getComputedStyle(node).transform));
            node = node.parentNode;
        }

        // Then, we take each corner of the container element in the shadow root and transform
        // each with the inverted matrix we just computed so that we can compute the untransformed
        // bounds of the media element.
        const bounds = this.container.getBoundingClientRect();
        const invertedTransform = transform.inverse();
        let minX = Infinity;
        let minY = Infinity;
        let maxX = -Infinity;
        let maxY = -Infinity;
        [
            new DOMPoint(bounds.left, bounds.top),
            new DOMPoint(bounds.right, bounds.top),
            new DOMPoint(bounds.right, bounds.bottom),
            new DOMPoint(bounds.left, bounds.bottom)
        ].forEach(corner => {
            const point = corner.matrixTransform(invertedTransform);
            if (point.x < minX)
                minX = point.x;
            if (point.x > maxX)
                maxX = point.x;
            if (point.y < minY)
                minY = point.y;
            if (point.y > maxY)
                maxY = point.y;
        });

        // Finally, we factor in the scale factor of the controls themselves, which reflects the page's scale factor.
        this.controls.width = Math.round((maxX - minX) * this.controls.scaleFactor);
        this.controls.height = Math.round((maxY - minY) * this.controls.scaleFactor);

        this.controls.shouldCenterControlsVertically = this.isAudio;
    }

    _controlsClassForLayoutTraits(layoutTraits)
    {
        if (layoutTraits & LayoutTraits.Compact)
            return CompactMediaControls;
        if (layoutTraits & LayoutTraits.iOS)
            return IOSInlineMediaControls;
        if (layoutTraits & LayoutTraits.Fullscreen)
            return MacOSFullscreenMediaControls;
        return MacOSInlineMediaControls;
    }

    _updateTextTracksClassList()
    {
        if (!this.host)
            return;

        const layoutTraits = this.layoutTraits;
        if (layoutTraits & LayoutTraits.Fullscreen)
            return;

        this.host.textTrackContainer.classList.toggle("visible-controls-bar", !this.controls.faded);
    }

    _controlsUserVisibilityDidChange()
    {
        if (!this.controls || !this._supportingObjects)
            return;

        this._supportingObjects.forEach(supportingObject => supportingObject.controlsUserVisibilityDidChange());
    }

    _shouldControlsBeAvailable()
    {
        // Controls are always available with compact layout.
        if (this.layoutTraits & LayoutTraits.Compact)
            return true;

        // Controls are always available while in fullscreen on macOS, and they are never available when in fullscreen on iOS.
        if (this.isFullscreen)
            return !!(this.layoutTraits & LayoutTraits.macOS);

        // Otherwise, for controls to be available, the controls attribute must be present on the media element
        // or the MediaControlsHost must indicate that controls are forced.
        return this.media.controls || !!(this.host && this.host.shouldForceControlsDisplay);
    }

    _updateControlsAvailability()
    {
        const shouldControlsBeAvailable = this._shouldControlsBeAvailable();
        if (!shouldControlsBeAvailable)
            this._supportingObjects.forEach(supportingObject => supportingObject.disable());
        else
            this._supportingObjects.forEach(supportingObject => supportingObject.enable());

        this.controls.visible = shouldControlsBeAvailable;
    }

}
