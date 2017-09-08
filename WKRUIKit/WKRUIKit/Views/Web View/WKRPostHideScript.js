var styleElement = document.createElement('style');
document.documentElement.appendChild(styleElement);

styleElement.textContent = `
sup { display: none !important; }
a[href^="/wiki/"] { background-color: #f5f5f5; font-weight: 500; }
a[href*=":"] { background-color: white; font-weight: 400; }

.header { display : none !important; }
.toc-mobile { display : none !important; }
.pre-content { padding-bottom: 15px; }
.content { padding-bottom: 40px; }
.footer { display: none !important; }

.new { display: none !important; }
.message { display: none !important; }
.reflist { display: none !important; }
.browse-tags { display: none !important; }
.read-more-container { display: none !important; }
.cleanup.mw-mf-cleanup { display: none !important; }

#edit-page { display : none !important; }
#page-actions { display : none !important; }
#page-secondary-actions { display : none !important; }

#mw-mf-cleanup { display: none !important; }
#mw-mf-last-modified { display: none !important; }
#mw-notification-content { display: none !important; }
.mw-ui-icon-edit-enabled { display: none !important; }

#siteNotice { display: none !important; }
#centralNotice { display: none !important; }
`;

document.documentElement.style.webkitTouchCallout='none';
document.documentElement.style.webkitUserSelect='none';

console.log("WKRUIKit: Added CSS");

var special = document.getElementsByClassName("floatnone");
for (var i = 0; i < special.length; i++) {
  special[i].innerHTML = "";
}

console.log("WKRUIKit: Removed Floats");

function cleanPage() {
  console.log("WKRUIKit: cleanPage");

  // Close the sections
  var headers = document.getElementsByClassName("section-heading");
  for (i = 0; i < headers.length; i++) {
    if (headers[i].className.indexOf("open-block") > 0) {
      headers[i].click();
    }
  }
  console.log("WKRUIKit: Closed Sections");

  // Hide dynamic tags
  var tagsToRemove = ["footer"];
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
  var sectionsToRemove = ["Notes_and_references", "Sources", "Footnotes", "Bibliography", "Notes", "References", "Further_reading", "External_links"];
  for (var i = 0; i < sectionsToRemove.length; i++) {
    var sectionHeaderContent = document.getElementById(sectionsToRemove[i]);

    try {
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
    } catch (error) {
      console.log("WKRUIKit: Section Error");
    }

  }
  console.log("WKRUIKit: Removed Sections");
}

var userInteracted = false
function setUserInteracted() {
  userInteracted = true
  console.log("WKRUIKit: User Interacted");
}
document.ontouchstart = setUserInteracted;
document.onmousedown = setUserInteracted;
window.onload = cleanPage();

var firstLength = 0;
var checks = 0;
var interval = setInterval(function() {
  checks += 1;
  console.log("WKRUIKit: Check (" + checks.toString() + ")");
  if (firstLength == 0) {
    firstLength = document.documentElement.innerHTML.length;
    console.log("WKRUIKit: Got first page length (" + firstLength.toString() + ")");
  } else if (firstLength + 100 < document.documentElement.innerHTML.length) {
    setTimeout(function() { cleanPage() }, 200);
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
