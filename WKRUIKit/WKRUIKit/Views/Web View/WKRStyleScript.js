var styleElement = document.createElement("style");
document.documentElement.appendChild(styleElement);

styleElement.textContent = `
sup {
    display: none !important;
}
a[href^="/wiki/"] {
    background-color: #f5f5f5; font-weight: 500;
}
a[href*=":"] {
    background-color: clear; font-weight: 400;
}
.pre-content {
    padding-bottom: 15px;
}
.content {
    padding-bottom: 40px;
}

@media screen and (min-width: 500px) {
    .pre-content {
        max-width: 90%;
    }
    #bodyContent {
        max-width: 90%;
    }
}

@media (prefers-color-scheme: dark) {
    img {
        filter: invert(1);
    }
    a {
        color: #B38519;
    }
    a[href^="/wiki/"] {
        background-color: rgba(0,0,0,0);
        color: #986400;
        font-weight: 500;
    }
    body {
        filter: invert(1);
        background-color: rgba(0,0,0,0);
    }
}
`;

document.documentElement.style.webkitTouchCallout = "none";
document.documentElement.style.webkitUserSelect = "none";
