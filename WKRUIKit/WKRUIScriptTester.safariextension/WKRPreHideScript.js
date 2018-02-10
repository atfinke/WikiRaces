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

.mbox-small { display : none !important; }
.edit-page { display : none !important; }
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
