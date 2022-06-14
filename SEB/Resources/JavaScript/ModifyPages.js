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
            if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
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

function SEB_jump(increment) {
    previousSelected = SEB_currentSelected;
    SEB_currentSelected = SEB_currentSelected + increment;
    
    if (SEB_currentSelected < 0) {
        SEB_currentSelected = SEB_SearchResultCount + SEB_currentSelected;
    }
    
    if (SEB_currentSelected >= SEB_SearchResultCount) {
        SEB_currentSelected = SEB_currentSelected - SEB_SearchResultCount;
    }
    
    previousElement = document.getElementsByClassName("SEB_FoundTextHighlight")[previousSelected];
    
    if (previousElement) {
        previousElement.style.backgroundColor="yellow";
    }
    currentElement = document.getElementsByClassName("SEB_FoundTextHighlight")[SEB_currentSelected];
    if (currentElement) {
        currentElement.style.backgroundColor="green";
        currentElement.scrollIntoView(true);
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
