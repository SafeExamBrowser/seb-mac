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


var SEB_SearchResultCount = 0;
var SEB_currentSelected = -1;

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

// Returns true only if the (highlight) element actually occupies space in the
// layout. Used as a safety net during navigation so we never land on a match
// that became invisible after it was created.
function SEB_IsRendered(element) {
    return element &&
           (element.offsetParent !== null || element.getClientRects().length > 0);
}

// helper function, recursively searches in elements and their child nodes
function SEB_HighlightAllOccurencesOfStringForElement(element,keyword) {
    if (element) {
        if (element.nodeType == 3) {        // Text node
            while (true) {
                var value = element.nodeValue;  // Search for keyword in text node
                var idx = value.toLowerCase().indexOf(keyword);
                
                if (idx < 0) break;             // not found, abort
                
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx,keyword.length));
                span.appendChild(text);
                span.setAttribute("class","SEB_FoundTextHighlight");
                span.style.backgroundColor="yellow";
                span.style.color="black";
                text = document.createTextNode(value.substr(idx+keyword.length));
                element.deleteData(idx, value.length - idx);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
                SEB_SearchResultCount++;    // update the counter
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
                        SEB_HighlightAllOccurencesOfStringForElement(frameDoc.body, keyword);
                    }
                } catch (e) {
                    // Cross-origin frame: access denied, skip it.
                }
                return;
            }
            // Never modify editable regions (e.g. rich text answer fields like
            // the OLAT/TinyMCE editor): injecting highlight spans into their
            // content makes the editor strip the span together with the wrapped
            // text, so the found word would disappear. isContentEditable is true
            // for a contenteditable element and all of its descendants.
            var isEditable = element.isContentEditable ||
                             nodeName == 'input' ||
                             nodeName == 'textarea';
            if (SEB_IsElementVisible(element) && nodeName != 'select' && !isEditable) {
                for (var i=element.childNodes.length-1; i>=0; i--) {
                    SEB_HighlightAllOccurencesOfStringForElement(element.childNodes[i],keyword);
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

// Collect all highlight spans across the top document and any same-origin
// frames, so that prev/next navigation also cycles through matches found
// inside iframes (cross-origin frames are skipped, as above).
function SEB_CollectHighlights(doc, result) {
    var highlights = doc.getElementsByClassName("SEB_FoundTextHighlight");
    for (var i=0; i<highlights.length; i++) {
        // Safety net: only navigate to matches that are actually visible.
        if (SEB_IsRendered(highlights[i])) {
            result.push(highlights[i]);
        }
    }
    var frames = doc.getElementsByTagName("iframe");
    for (var j=0; j<frames.length; j++) {
        try {
            var frameDoc = frames[j].contentDocument;
            if (frameDoc) {
                SEB_CollectHighlights(frameDoc, result);
            }
        } catch (e) {
            // Cross-origin frame: access denied, skip it.
        }
    }
    return result;
}

function SEB_jump(increment) {
    var highlights = SEB_CollectHighlights(document, []);
    if (highlights.length == 0) {
        return;
    }
    previousSelected = SEB_currentSelected;
    SEB_currentSelected = SEB_currentSelected + increment;

    if (SEB_currentSelected < 0) {
        SEB_currentSelected = highlights.length + SEB_currentSelected;
    }

    if (SEB_currentSelected >= highlights.length) {
        SEB_currentSelected = SEB_currentSelected - highlights.length;
    }

    previousElement = highlights[previousSelected];

    if (previousElement) {
        previousElement.style.backgroundColor="yellow";
    }
    currentElement = highlights[SEB_currentSelected];
    if (currentElement) {
        currentElement.style.backgroundColor="green";
        // Center the match vertically rather than aligning it to the very top
        // of the viewport, so results near the top of the page aren't hidden
        // behind SEB's title/search bar overlay. (On pages too short to scroll,
        // the top area can still be partly covered - the browser cannot scroll
        // further than the page allows.)
        currentElement.scrollIntoView({block: "center", inline: "nearest"});
    }
}

// the main entry point to start the search
function SEB_HighlightAllOccurencesOfString(keyword) {
    SEB_RemoveAllHighlights();
    SEB_HighlightAllOccurencesOfStringForElement(document.body, keyword.toLowerCase());
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

// the main entry point to remove the highlights
function SEB_RemoveAllHighlights() {
    SEB_SearchResultCount = 0;
    SEB_currentSelected = -1;
    SEB_RemoveAllHighlightsForElement(document.body);
};
