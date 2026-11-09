function SEB_ModifyLinkTargets() {
    var allLinks = document.getElementsByTagName('a');
    if (allLinks) {
        var i;
        for (i=0; i<allLinks.length; i++) {
            var link = allLinks[i];
            var target = link.getAttribute('target');
            if (target && target == '_blank') {
                link.setAttribute('target','_self');
                link.href = 'newtab:'+escape(link.href);
            }
        }
    }
}


function SEB_ModifyWindowOpen() {
    window.open =
    function(url,target,param) {
        if (url && url.length > 0) {
            url = url.trim();
            if (url.indexOf('/') === 0) {
                // relative root url e.g. /somePath/etc
                url = window.location.origin + url;
            } else if (url.indexOf('://') === -1) {
                // relative url  e.g. someSubPath/etc as no protocol is in the url
                var hrefPart = window.location.href;
                if (hrefPart.substring(hrefPart.length -1) === '/') {
                    // if the hrefPart ends with /
                    url = hrefPart + url;
                } else {
                    url = hrefPart + '/' + url;
                }

            }
            if (!target) target = "_blank";
            if (target == '_blank') {
                location.href = 'newtab:'+escape(url);
            } else {
                location.href = url;
            }
        }
    }
}


function SEB_increaseMaxZoomFactor() {
    var element = document.createElement('meta');
    element.name = "viewport";
    element.content = "maximum-scale=10";
    var head = document.getElementsByTagName('head')[0];
    head.appendChild(element);
}


function SEB_replaceImage(base64Data) {
    var picture = document.getElementsByClassName('img-responsive')[0];
    picture.src = "data:image/png;base64,"+base64Data;
}


function SEB_AllowSpellCheck(enable) {
    var txtFields = document.getElementsByTagName('input');
    if (txtFields) {
        var i;
        for (i = 0; i < txtFields.length; i++) {
            var txtField = txtFields[i];
            var attributeValue = enable ? 'on' : 'off';
            if (txtField) {
                txtField.setAttribute('autocomplete',attributeValue);
                txtField.setAttribute('autocorrect',attributeValue);
                txtField.setAttribute('autocapitalize',attributeValue);
                txtField.setAttribute('spellcheck',enable);
            }
        }
    }
    txtFields = document.getElementsByTagName('textarea');
    if (txtFields) {
        var i;
        for (i = 0; i < txtFields.length; i++) {
            var txtField = txtFields[i];
            if (txtField) {
                txtField.setAttribute('autocomplete',attributeValue);
                txtField.setAttribute('autocorrect',attributeValue);
                txtField.setAttribute('autocapitalize',attributeValue);
                txtField.setAttribute('spellcheck',enable);
            }
        }
    }
    txtFields = document.querySelectorAll('[contenteditable=true]');
    if (txtFields) {
        var i;
        for (i = 0; i < txtFields.length; i++) {
            var txtField = txtFields[i];
            if (txtField) {
                txtField.setAttribute('autocomplete',attributeValue);
                txtField.setAttribute('autocorrect',attributeValue);
                txtField.setAttribute('autocapitalize',attributeValue);
                txtField.setAttribute('spellcheck',enable);
            }
        }
    }
}

function SEB_GetAllFocusableElements() {
    var elements = document.body.querySelectorAll('a[href]:not([disabled]), button:not([disabled]), textarea:not([disabled]), input[type="text"]:not([disabled]), input[type="radio"]:not([disabled]), input[type="checkbox"]:not([disabled]), select:not([disabled]), details:not([disabled]), summary:not([disabled])');
    return elements;
}

function SEB_FocusFirstElement() {
    var firstFocusable = SEB_GetAllFocusableElements()[0];
    firstFocusable.focus();
}

function SEB_FocusLastElement() {
    var focusableElements = SEB_GetAllFocusableElements();
    var lastFocusable = focusableElements[focusableElements.length - 1];
    lastFocusable.focus();
}


var SEB_SearchResultCount = 0;   // total navigable matches (highlights + editable ranges)
var SEB_currentSelected = -1;    // 0-based index into SEB_matches, -1 = none selected

// Ordered list (document order) of all matches of the current search. Each
// entry is one of:
//   - a highlight match:  { editable: false, span: <span element> }
//   - an editable match:  { editable: true, node: <text node>, index: n, length: n }
// Editable matches (inside a contenteditable answer field) are NOT wrapped in
// a highlight span - that would modify the candidate's answer - they are only
// recorded so we can select/scroll to them with the Selection API.
var SEB_matches = [];

// Returns false for elements that are not rendered (display:none or
// visibility:hidden/collapse). Because we test this on every element while
// descending, hitting a hidden container stops us before we reach its
// (hidden) descendants — e.g. the accessibility clones a rich text editor
// keeps in the DOM. That keeps invisible text from being highlighted, which
// in turn keeps prev/next navigation from stopping on unseen matches.
function SEB_IsElementVisible(element) {
    var doc = element.ownerDocument;
    var win = (doc && doc.defaultView) || window;
    var style = win.getComputedStyle(element);
    if (!style) {
        return true;
    }
    return style.display != "none" &&
           style.visibility != "hidden" &&
           style.visibility != "collapse";
}

// Returns true only if the element actually occupies space in the layout. Used
// as a safety net so we never navigate to a match that isn't visible.
function SEB_IsRendered(element) {
    return element &&
           (element.offsetParent !== null || element.getClientRects().length > 0);
}

// Returns true if a recorded match is currently navigable (visible).
function SEB_MatchVisible(match) {
    if (match.editable) {
        return SEB_IsRendered(match.node.parentElement);
    }
    return SEB_IsRendered(match.span);
}

// Returns the outermost contiguous contenteditable ancestor (the editing host)
// of a node, so we can focus it before selecting a match inside it.
function SEB_EditableHost(node) {
    var element = (node.nodeType == 1) ? node : node.parentElement;
    var host = null;
    while (element) {
        if (element.isContentEditable) {
            host = element;
        } else if (host) {
            break;
        }
        element = element.parentElement;
    }
    return host;
}

// helper function, recursively searches in elements and their child nodes.
// "editable" is true once we've descended into a contenteditable region; there
// we record matches without modifying the DOM instead of injecting highlights.
function SEB_HighlightAllOccurencesOfStringForElement(element,keyword,editable) {
    if (element) {
        if (element.nodeType == 3) {        // Text node
            if (editable) {
                // Editable region: just record the match, don't touch the DOM.
                var value = element.nodeValue;
                var lower = value.toLowerCase();
                var from = 0;
                while (true) {
                    var idx = lower.indexOf(keyword, from);
                    if (idx < 0) break;
                    SEB_matches.push({editable:true, node:element, index:idx, length:keyword.length});
                    from = idx + keyword.length;
                }
            } else {
                var doc = element.ownerDocument;
                while (true) {
                    var value = element.nodeValue;  // Search for keyword in text node
                    var idx = value.toLowerCase().indexOf(keyword);

                    if (idx < 0) break;             // not found, abort

                    var span = doc.createElement("span");
                    var text = doc.createTextNode(value.substr(idx,keyword.length));
                    span.appendChild(text);
                    span.setAttribute("class","SEB_FoundTextHighlight");
                    span.style.backgroundColor="yellow";
                    span.style.color="black";
                    text = doc.createTextNode(value.substr(idx+keyword.length));
                    element.deleteData(idx, value.length - idx);
                    var next = element.nextSibling;
                    element.parentNode.insertBefore(span, next);
                    element.parentNode.insertBefore(text, next);
                    element = text;
                    SEB_matches.push({editable:false, span:span});
                }
            }
        } else if (element.nodeType == 1) { // Element node
            var nodeName = element.nodeName.toLowerCase();
            if (nodeName == 'iframe' || nodeName == 'frame') {
                // Descend into (same-origin) frames as well. Accessing the
                // contentDocument of a cross-origin frame throws a SecurityError,
                // so we guard it and simply skip frames we're not allowed to read.
                try {
                    var frameDoc = element.contentDocument;
                    if (frameDoc && frameDoc.body) {
                        SEB_HighlightAllOccurencesOfStringForElement(frameDoc.body, keyword, editable);
                    }
                } catch (e) {
                    // Cross-origin frame: access denied, skip it.
                }
                return;
            }
            // Form fields are not searched (their value isn't in child text
            // nodes we can navigate to).
            if (nodeName == 'select' || nodeName == 'input' || nodeName == 'textarea') {
                return;
            }
            if (SEB_IsElementVisible(element)) {
                // Once inside a contenteditable, stay in "editable" mode so we
                // record matches instead of injecting highlight spans (which
                // would alter the answer). isContentEditable is true for a
                // contenteditable element and all of its descendants.
                var nowEditable = editable || element.isContentEditable;
                // Snapshot the child nodes first: injecting highlight spans adds
                // new siblings, and iterating a live list would revisit them
                // (and re-match the highlighted keyword). The snapshot lets us
                // walk in forward document order, so SEB_matches ends up ordered.
                var children = [];
                for (var c=0; c<element.childNodes.length; c++) {
                    children.push(element.childNodes[c]);
                }
                for (var i=0; i<children.length; i++) {
                    SEB_HighlightAllOccurencesOfStringForElement(children[i],keyword,nowEditable);
                }
            }
        }
    }
}

function SEB_SearchNext() {
    SEB_jump(1);
}

function SEB_SearchPrevious() {
    SEB_jump(-1);
}

// Removes the visual selection of the match at the given index (revert the
// highlight span colour, or clear the text selection in an editable field).
function SEB_deactivateMatch(index) {
    if (index < 0 || index >= SEB_matches.length) {
        return;
    }
    var match = SEB_matches[index];
    if (match.editable) {
        try {
            var win = match.node.ownerDocument.defaultView || window;
            win.getSelection().removeAllRanges();
        } catch (e) {}
    } else if (match.span) {
        match.span.style.backgroundColor="yellow";
    }
}

// Selects and scrolls to the match at the given index.
function SEB_activateMatch(index) {
    if (index < 0 || index >= SEB_matches.length) {
        return;
    }
    var match = SEB_matches[index];
    if (match.editable) {
        // Select the matched text via the Selection API (no DOM change) and
        // focus the editing host, so the answer field shows the native
        // selection/caret at the match.
        var doc = match.node.ownerDocument;
        var win = doc.defaultView || window;
        var range = doc.createRange();
        try {
            range.setStart(match.node, match.index);
            range.setEnd(match.node, match.index + match.length);
        } catch (e) {
            return;
        }
        var host = SEB_EditableHost(match.node);
        if (host && host.focus) {
            try { host.focus({preventScroll:true}); } catch (e) { host.focus(); }
        }
        var selection = win.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        var rectElement = match.node.parentElement || host;
        if (rectElement) {
            rectElement.scrollIntoView({block: "center", inline: "nearest"});
        }
    } else if (match.span) {
        match.span.style.backgroundColor="green";
        // Center the match vertically rather than aligning it to the very top
        // of the viewport, so results near the top of the page aren't hidden
        // behind SEB's title/search bar overlay. (On pages too short to scroll,
        // the top area can still be partly covered - the browser cannot scroll
        // further than the page allows.)
        match.span.scrollIntoView({block: "center", inline: "nearest"});
    }
}

function SEB_jump(increment) {
    if (SEB_matches.length == 0) {
        SEB_currentSelected = -1;
        return;
    }
    SEB_deactivateMatch(SEB_currentSelected);

    SEB_currentSelected = SEB_currentSelected + increment;
    if (SEB_currentSelected < 0) {
        SEB_currentSelected = SEB_matches.length + SEB_currentSelected;
    }
    if (SEB_currentSelected >= SEB_matches.length) {
        SEB_currentSelected = SEB_currentSelected - SEB_matches.length;
    }

    SEB_activateMatch(SEB_currentSelected);
}

// Returns [currentResultNumber, totalResults] for the native "N of M" display.
// currentResultNumber is 1-based, or 0 when nothing is selected yet.
function SEB_SearchStatus() {
    var current = (SEB_matches.length > 0 && SEB_currentSelected >= 0) ? (SEB_currentSelected + 1) : 0;
    return [current, SEB_SearchResultCount];
}

// the main entry point to start the search
function SEB_HighlightAllOccurencesOfString(keyword) {
    SEB_RemoveAllHighlights();
    SEB_HighlightAllOccurencesOfStringForElement(document.body, keyword.toLowerCase(), false);
    // Keep only matches that are actually visible/navigable.
    SEB_matches = SEB_matches.filter(SEB_MatchVisible);
    SEB_SearchResultCount = SEB_matches.length;
}

// helper function, recursively removes the highlights in elements and their childs
function SEB_RemoveAllHighlightsForElement(element) {
    if (element) {
        if (element.nodeType == 1) {
            var nodeName = element.nodeName.toLowerCase();
            if (nodeName == 'iframe' || nodeName == 'frame') {
                // Remove highlights inside (same-origin) frames as well.
                try {
                    var frameDoc = element.contentDocument;
                    if (frameDoc && frameDoc.body) {
                        SEB_RemoveAllHighlightsForElement(frameDoc.body);
                    }
                } catch (e) {
                    // Cross-origin frame: access denied, skip it.
                }
                return false;
            }
            if (element.getAttribute("class") == "SEB_FoundTextHighlight") {
                var text = element.removeChild(element.firstChild);
                element.parentNode.insertBefore(text,element);
                element.parentNode.removeChild(element);
                return true;
            } else {
                var normalize = false;
                for (var i=element.childNodes.length-1; i>=0; i--) {
                    if (SEB_RemoveAllHighlightsForElement(element.childNodes[i])) {
                        normalize = true;
                    }
                }
                if (normalize) {
                    element.normalize();
                }
            }
        }
    }
    return false;
}

// Clears any text selection we set for an editable match, in the top document
// and in every same-origin frame.
function SEB_ClearActiveSelection() {
    try { window.getSelection().removeAllRanges(); } catch (e) {}
    var frames = document.getElementsByTagName("iframe");
    for (var j=0; j<frames.length; j++) {
        try {
            var frameWindow = frames[j].contentWindow;
            if (frameWindow) {
                frameWindow.getSelection().removeAllRanges();
            }
        } catch (e) {
            // Cross-origin frame: access denied, skip it.
        }
    }
}

// the main entry point to remove the highlights
function SEB_RemoveAllHighlights() {
    SEB_ClearActiveSelection();
    SEB_SearchResultCount = 0;
    SEB_currentSelected = -1;
    SEB_matches = [];
    SEB_RemoveAllHighlightsForElement(document.body);
};
