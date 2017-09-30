var links = document.getElementById("bodyContent").getElementsByTagName("a");
for (var i = 0; i < links.length; i++) {
    if (links[i].parentElement.className != "mw-whatlinkshere-tools" && links[i].parentElement.parentElement.id == "mw-whatlinkshere-list") {
        webkit.messageHandlers.linkedPage.postMessage(links[i].href);
    } else if (links[i].textContent == "next 500" && links[i].href != window.location.href) {
        webkit.messageHandlers.nextPage.postMessage(links[i].href);
    }
}
webkit.messageHandlers.finishedPage.postMessage("");
