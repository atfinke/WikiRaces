var pixelsScrolled = 0;
var lastPixelOffset = 0;

window.onscroll = function () {
    let scrollY = window.scrollY
    pixelsScrolled += Math.abs(scrollY - lastPixelOffset);
    lastPixelOffset = scrollY;
};

document.body.onclick = function(e){
    webkit.messageHandlers.scrollY.postMessage(pixelsScrolled);
    pixelsScrolled = 0;
    return true
};

function cleanPage() {
    console.log("WKRUIKit: cleanPage");

    // Close the sections
    if (window.location.href.indexOf("#") == -1) {
        var headers = document.getElementsByClassName("section-heading");
        for (i = 0; i < headers.length; i++) {
            if (headers[i].className.indexOf("open-block") > 0) {
                headers[i].click();
            }
        }
        console.log("WKRUIKit: Closed Sections");
    }

    // Hide dynamic tags
    let tagsToRemove = ["footer"];
    for (i = 0; i < tagsToRemove.length; i++) {
        try {
            var elements = document.getElementsByTagName(tagsToRemove[i]);
            for (var i = 0; i < elements.length; i++) {
                elements[i].parentElement.removeChild(elements[i]);
            }
        } catch (error) {
            console.log("WKRUIKit: Tag Error");
        }
    }
    console.log("WKRUIKit: Removed Tags");

    // Remove sections
    let sectionsToRemove = [
        "Notes_and_references",
        "Sources",
        "Footnotes",
        "Bibliography",
        "Notes",
        "References",
        "Further_reading",
        "External_links",
        "Links",
    ];
    for (var i = 0; i < sectionsToRemove.length; i++) {
        try {
            let sectionHeadlineSpanElement = document.getElementById(sectionsToRemove[i]);
            let sectionID = sectionHeadlineSpanElement.getAttribute("aria-controls");
            if (sectionID != null) {
                let sectionHeadingElement = sectionHeadlineSpanElement.parentElement;
                let sectionSectionElement = document.getElementById(sectionID);
                sectionHeadingElement.parentElement.removeChild(sectionHeadingElement);
                sectionSectionElement.parentElement.removeChild(sectionSectionElement);
                console.log("WKRUIKit: Removed: " + sectionsToRemove[i]);
            }
        } catch (error) {
        }
    }
    console.log("WKRUIKit: Removed Sections");
}

var userInteracted = false;
function setUserInteracted() {
    userInteracted = true;
    console.log("WKRUIKit: User Interacted");
}
document.ontouchstart = setUserInteracted;
document.onmousedown = setUserInteracted;
window.onload = cleanPage();

var firstLength = 0;
var checks = 0;
var interval = setInterval(function () {
    checks += 1;
    console.log("WKRUIKit: Check (" + checks.toString() + ")");
    if (firstLength == 0) {
        firstLength = document.documentElement.innerHTML.length;
        console.log("WKRUIKit: Got first page length (" + firstLength.toString() + ")");
    } else if (firstLength + 100 < document.documentElement.innerHTML.length) {
        setTimeout(function () {
            cleanPage();
        }, 200);
        clearInterval(interval);
        console.log("WKRUIKit: Got longer page length (" + document.documentElement.innerHTML.length.toString() + ")");
        return;
    } else if (checks > 500) {
        cleanPage();
        clearInterval(interval);
        console.log("WKRUIKit: Stopped checking for load due to check count");
        return;
    } else if (userInteracted) {
        clearInterval(interval);
        console.log("WKRUIKit: Stopped checking for load due to interaction");
        return;
    }
}, 10);

(function () {
    var oldLog = console.log;
    console.log = function (message) {
        if (
            message.includes(
                "Wikipedia is powered by MediaWiki. MediaWiki is open source software and we're always keen to hear from fellow developers"
            )
        ) {
            console.log("WKRUIKit: Got MediaWiki console message");
            setTimeout(function () {
                cleanPage();
            }, 100);
        }
        oldLog.apply(console, arguments);
    };
})();
