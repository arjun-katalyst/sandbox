// Katalyst Exam Firefox preferences. Copied into a fresh profile at every session start.
// Hard restrictions (allowlist, devtools, add-ons, about: pages) live in policies.json.

// Restore tabs when the browser is relaunched after an unauthorised exit/crash
user_pref("browser.startup.page", 3);
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("browser.sessionstore.max_resumed_crashes", 1000);
user_pref("browser.sessionstore.restore_on_demand", false);
user_pref("toolkit.startup.max_resumed_crashes", -1);

// No "are you sure" prompts; the exit guard handles quitting
user_pref("browser.warnOnQuit", false);
user_pref("browser.warnOnQuitShortcut", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.closeWindowWithLastTab", true);

// New-tab links open as tabs, which katalyst-exam.cfg folds into the exam tab
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);
user_pref("browser.tabs.allowTabDetach", false);
user_pref("browser.newtabpage.enabled", false);
user_pref("middlemouse.contentLoadURL", false);
user_pref("ui.key.menuAccessKeyFocuses", false);

// First-run / nag screens
user_pref("browser.aboutwelcome.enabled", false);
user_pref("trailhead.firstrun.didSeeAboutWelcome", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);

// File dialogs: plain GTK chooser (no portals inside the exam session)
user_pref("widget.use-xdg-desktop-portal.file-picker", 0);
user_pref("widget.use-xdg-desktop-portal.mime-handler", 0);
user_pref("widget.use-xdg-desktop-portal.open-uri", 0);

// Downloads: save silently, never offer "Open with <program>"
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.always_ask_before_handling_new_types", false);
user_pref("browser.download.forbid_open_with", true);
user_pref("browser.download.alwaysOpenPanel", false);
user_pref("helpers.global_mailcap_file", "");
user_pref("helpers.private_mailcap_file", "");
user_pref("helpers.global_mime_types_file", "");
user_pref("helpers.private_mime_types_file", "");

// No built-in AI chatbot sidebar or translation model downloads
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.enable", false);
user_pref("browser.translations.enable", false);

// Don't keep students' credentials or form data on a shared machine
user_pref("signon.rememberSignons", false);
user_pref("browser.formfill.enable", false);

user_pref("app.update.auto", false);
