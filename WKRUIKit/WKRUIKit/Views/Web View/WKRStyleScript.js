var styleElement = document.createElement('style');
document.documentElement.appendChild(styleElement);

styleElement.textContent = `
sup { display: none !important; }
a[href^="/wiki/"] { background-color: #f5f5f5; font-weight: 500; }
a[href*=":"] { background-color: clear; font-weight: 400; }
.pre-content { padding-bottom: 15px; }
.content { padding-bottom: 40px; }
`;

document.documentElement.style.webkitTouchCallout='none';
document.documentElement.style.webkitUserSelect='none';
