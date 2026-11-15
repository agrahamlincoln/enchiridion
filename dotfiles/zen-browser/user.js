// Enchiridion — Zen Browser preferences
// Symlinked into the active Zen profile by setup.sh.

// Enable userChrome.css and userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Dark theme
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.theme.content-theme", 0);      // 0 = dark
user_pref("browser.theme.toolbar-theme", 0);

// Accent color — overrides per-workspace gradient colors
user_pref("zen.theme.accent-color", "#1793d1");

// Solid background — disable the translucent gradient overlay
user_pref("zen.view.window.scheme", 2);            // 0=gradient, 2=solid

// Privacy-respecting defaults
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// Home page: genkan, the home-lab portal (every lab web UI with live status).
// Firefox has no pref for the new-tab URL, so only the home button and
// "Home" startup use it. browser.startup.page stays as is to keep session restore.
user_pref("browser.startup.homepage", "https://lab.agrahamlincoln.com");
