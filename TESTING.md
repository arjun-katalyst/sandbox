# Pilot checklist

Run on **one** real lab machine (and a 22.04, a 24.04 and/or a Debian 12+ machine
if the lab is mixed) before rolling out. Record results; anything that fails is a blocker.

## A. Install

- [ ] `sudo ./install.sh` completes; `katalyst-exam-admin status` shows no `[!!]`
- [ ] Normal Firefox for other users still opens and is **not** restricted
- [ ] `katalyst-exam-admin test-policies` (no sudo, from a normal desktop) → about:policies
      shows the policies as **Active** with no errors

## B. Session start

- [ ] Login screen lists **Katalyst Exam**; wrong password is rejected
- [ ] Correct password → round picker shows both rounds; each opens the right Kaggle URL
- [ ] With only one ROUND_ line, Kaggle opens directly without the picker
- [ ] After picking a round, Kaggle opens full screen, no address bar, no tabs, no desktop
- [ ] Machine with NVIDIA GPU: if black screen, `sudo katalyst-exam-admin force-x11 on` and retry

## C. Kaggle domain discovery (allowlist)

On a **normal desktop**, open Firefox ESR with the exam policies
(`katalyst-exam-admin test-policies`), then in a new tab do everything a student will do:

- [ ] Sign in with an email account (incl. the reCAPTCHA)
- [ ] Open **both** exam competitions/notebooks (ML and Coding round URLs)
- [ ] Edit and **run** a notebook cell; wait for the kernel to start
- [ ] Upload a file to a notebook / dataset
- [ ] Submit to the competition
- [ ] Check the notebook and the Browser Console (Ctrl+Shift+J works only
      outside the exam session if devtools are allowed; otherwise watch for broken
      pages / "blocked by your organisation") — add missing domains to
      `config/allowlist.txt`, rebuild, retest

## D. Escape attempts (inside the exam session)

Each must do **nothing** or stay inside the allowlisted site:

- [ ] Alt+Tab, Super/Windows key, Alt+F2, Ctrl+Alt+T
- [ ] Ctrl+Alt+F1 … F12 (console switching)
- [ ] Ctrl+Alt+Backspace, Ctrl+Alt+Del
- [ ] F11, Esc, Alt+F4
- [ ] **Single tab:** Ctrl+T, Ctrl+N, Ctrl+Shift+P, Ctrl+Shift+T, Ctrl+Shift+N → nothing
      opens (or it closes instantly); Ctrl+Tab / Ctrl+PgDn have nothing to switch to
- [ ] Middle-click / Ctrl+click / right-click "Open in new tab" on a Kaggle link →
      no second tab; a Kaggle link that normally opens a new tab opens in the same tab
- [ ] Ctrl+W, Ctrl+Shift+W → nothing happens (Ctrl+Q still shows the exit screen)
- [ ] Still working: Ctrl+F (find), F5 (reload), Alt+Home (back to the round's page)
- [ ] Exam bar at the top: shows the round name; Back/Forward work and are greyed
      out when there is nowhere to go; Reload and Exam home work; Alt+Left/Right too
- [ ] Ctrl+L / F6 then type a URL; Ctrl+K; Alt+Home
- [ ] Ctrl+Shift+I / F12 (devtools), Ctrl+U (view source)
- [ ] Ctrl+Shift+A (add-ons), Ctrl+Shift+B / Ctrl+Shift+O / Ctrl+Shift+Y (Library windows)
- [ ] Alt / Alt+E / Alt+T menus → Settings
- [ ] Ctrl+O (open file), Ctrl+S (save page), Ctrl+P (print)
- [ ] F1 (help), right-click menus
- [ ] Middle-click and Ctrl+click on links; drag a link to the screen edge
- [ ] A link on Kaggle to an outside site (e.g. GitHub) → **blocked page**
- [ ] Download a file, then try to *open* it / "Show in folder" from the downloads panel
      or Library → must NOT open a file manager, editor or terminal
- [ ] In the upload dialog: browse `/`, `/home`, `/media`; other users' homes not readable;
      right-click → no "Open with" / "Show in file manager" that launches an app
- [ ] Plug in a USB stick → not mounted, not visible in the upload dialog
      (unless `usb allow`)
- [ ] Plug in a phone (MTP) → not visible in the upload dialog

## E. Close / restart behaviour

- [ ] Ctrl+Q → exit guard appears; **Return to exam** → Firefox back with same tab
      and the **same round** (no round picker)
- [ ] Close every tab → after relaunch, Alt+Home goes to the chosen round's URL
- [ ] Exit guard: wrong password → error + delay; idle 60 s → returns to exam
- [ ] Exit guard: correct exit password → back to login screen
- [ ] Log in again → fresh session: not signed in to Kaggle, no history, Downloads empty
- [ ] Hold power button / reboot → comes back to the **login screen** (no auto-login)

## F. Terminal round (if configured)

- [ ] Picking the round opens a full-screen terminal, not Firefox
- [ ] Only `nano` and `python3` run; any other command (`ls`, `bash`, `cat`) fails
- [ ] `cd` outside `~/challenge` is blocked (restricted shell)
- [ ] Challenge files are present in `~/challenge`, including `answer.txt`
- [ ] Editing `answer.txt` in `nano` and exiting the terminal early → exit-guard
      appears; correct password ends the round and saves a submission file
      under `/var/lib/katalyst-exam/submissions/`
- [ ] Wait the full 45 minutes → terminal is killed automatically, a
      `...-timeout.txt` submission appears, and the **time's up** screen shows
      with no way back into the round (only the exit password works)
- [ ] Submissions from a previous session are still present after a fresh login
      (only `$HOME` is wiped, not `/var/lib/katalyst-exam/submissions`)
- [ ] Typed commands appear in `sudo cat /var/lib/katalyst-exam/monitor/history.log`
      (as root) after the round, with timestamps
- [ ] `sudo cat /var/lib/katalyst-exam/monitor/process.log` shows periodic
      `ps` snapshots while the round was running
- [ ] As the `exam` user: `cat ~/../../var/lib/katalyst-exam/monitor/history.log`
      (or any attempt to read/delete it) fails — permission denied
- [ ] No way to launch a browser from the restricted shell (`firefox`,
      `/usr/bin/firefox-esr`, etc. all fail)

## G. Uninstall

- [ ] `sudo ./install.sh --uninstall` → Katalyst Exam user gone from login screen,
      normal accounts unaffected
