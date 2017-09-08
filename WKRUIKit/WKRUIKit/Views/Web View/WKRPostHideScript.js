var styleElement = document.createElement('style');
document.documentElement.appendChild(styleElement);
styleElement.textContent = `
a[href^="/wiki/"] { background-color: #f5f5f5; font-weight: 500; }
a[href*=":"] { background-color: white; font-weight: 400; }
`;

var special = document.getElementsByClassName("floatnone");
for (var i = 0; i < special.length; i++) {
    special[i].innerHTML = "";
}

function makeThingsLookNice() {
    // Close the sections
    var headers = document.getElementsByClassName("section-heading");
    for (var i = 0; i < headers.length; i++) {
        if (headers[i].className.indexOf("open-block") > 0) {
            headers[i].click();
        }
    }

    // Hide dynamic tags
    var tagsToRemove = ["footer"]
    for (var i = 0; i < tagsToRemove.length; i++) {
        var elements = document.getElementsByTagName(tagsToRemove[i]);
        for (var i = 0; i < elements.length; i++) {
            elements[i].parentElement.removeChild(elements[i]);
        }
    }

    // Remove sections
    var sectionsToRemove = ["Footnotes", "Bibliography", "Notes", "References", "Further_reading", "External_links"];
    for (var i = 0; i < sectionsToRemove.length; i++) {
        var sectionHeaderContent = document.getElementById(sectionsToRemove[i]);

        if (typeof sectionHeaderContent !== 'undefined' && sectionHeaderContent != null) {
            var sectionHeader = sectionHeaderContent.parentElement;

            var sectionContentID = sectionHeader.getAttribute("aria-controls");
            var sectionContent = document.getElementById(sectionContentID);
            if (typeof sectionContent !== 'undefined' && sectionContent != null) {
                var sectionHeaderParent = sectionHeader.parentElement;
                var sectionContentParent =  sectionContent.parentElement;
                if (typeof sectionHeaderParent !== 'undefined' && sectionHeaderParent != null && typeof sectionContentParent !== 'undefined' && sectionContentParent != null) {
                    sectionHeaderParent.removeChild(sectionHeader);
                    sectionContentParent.removeChild(sectionContent);
                }
            }
        }
    }
}

var firstLength = 0;
var checks = 0;
var interval = setInterval(function() {
                           checks += 1;
                           if (firstLength == 0) {
                           firstLength = document.documentElement.innerHTML.length;
                           } else if (firstLength < document.documentElement.innerHTML.length) {
                           setTimeout(function() { makeThingsLookNice() }, 200);
                           clearInterval(interval);
                           return;
                           } else if (checks > 50) {
                           setTimeout(function() { makeThingsLookNice() }, 6000);
                           clearInterval(interval);
                           return;
                           }
                           }, 10);
