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


function SEB_simulateDrop(base64Data) {
    //var fileInput = document.getElementsByClassName('img-responsive')[0];
    
    var picture = document.getElementsByClassName('img-responsive')[0];
    picture.src = "data:image/png;base64,"+base64Data;

    var pictureBlob = new Blob([picture], {type: 'image/png'});
    file = new File([pictureBlob], "filename.png")

    filemanager-container.drop({
                  dataTransfer: { files: [ file ] }
                         });
}


function createFile(create) {
    var create = ["iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="];
    var blob = new Blob([create], {"type" : "image/png"});
    return ( blob.size > 0 ? blob : "file creation error" )
};