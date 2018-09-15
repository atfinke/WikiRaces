var styleElement = document.createElement('style');
document.documentElement.appendChild(styleElement);

styleElement.textContent = `
a { filter: invert(1); }
a[href^="/wiki/"] { background-color: rgba(0,0,0,0); color: #679bff; font-weight: 500; }
`;

document.documentElement.style.filter = "invert(1)"
