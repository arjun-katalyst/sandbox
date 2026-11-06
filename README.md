# Katalyst Exam

Locks Ubuntu 22.04+ or Debian 12 (bookworm)+ lab machines into a full-screen
Firefox ESR that can only open allowlisted sites (Kaggle), for proctored
coding assessments.

- **Password to open** — invigilator logs in as the *Katalyst Exam* user, then
  picks the exam round (e.g. *ML round* / *Coding round*).
- **Password to close** — closing the browser shows a full-screen prompt; without
  the invigilator exit password the browser comes straight back with its tabs.
- **No escape** — the session runs inside `cage` (one app, no desktop, no
  Alt+Tab, no Ctrl+Alt+Fn). X11 fallback for machines without Wayland.
- **Allowlist** — Firefox enterprise policy blocks every site not listed.
- **Exam bar** — slim bar with Back, Forward, Reload, Exam home and the round
  name (Firefox's own toolbar/address bar stay hidden).
- **One tab only** — new tabs/windows are closed instantly, links open in the
  same tab, and browser shortcuts (Ctrl+T/N/W/L/O/S/P/U, history, downloads…)
  are disabled. Ctrl+F, reload and Ctrl+Q (invigilator exit) still work.
- **Fresh every session** — no logins, history or downloads carry over.
- **USB storage blocked** for the exam user (configurable).
- Students' / teachers' normal accounts and normal Firefox are not affected.

## How it fits together

```
GDM login ── "Katalyst Exam" user (login password)
  └─ cage (Wayland)  or  Xorg + matchbox (fallback)
       └─ exam-session ── round picker (if 2+ rounds configured)
            ├─ firefox-esr --kiosk   (policies.json: allowlist, no devtools/add-ons/about:)
            │    └─ on any exit → exit-guard
            │           correct exit password → session ends → login screen
            │           anything else         → relaunch Firefox, tabs restored
            └─ terminal-session (ROUND_n=Label|terminal:<challenge-name>)
                 restricted shell (nano + python3 only), 45-min hard limit
                 └─ time limit reached  → answer snapshotted → time-up screen (invigilator password only, no return)
                 └─ closed/exited early → exit-guard (same as above, snapshots answer on authorised exit)
```

A terminal round is **not** a hard security sandbox — see "Limits" below.

| Path | Purpose |
|---|---|
| `config/allowlist.txt` | Sites the exam browser may open |
| `config/exam.conf` | Exam rounds (label + Kaggle URL or `terminal:<name>`), USB, X11 override |
| `challenges/` | Terminal-round challenge sources (candidate files + admin answer key) |
| `build-installer.sh` | Builds the installer folder (asks for both passwords) |
| `installer/install.sh` | Runs on each lab machine |
| `pkg/` | Contents of `katalyst-exam.deb`, incl. `pkg/usr/share/katalyst-exam/challenge/` |
| `TESTING.md` | Pilot checklist — **do this before exam day** |
| `tools/preview-ui` | Preview the round picker / exit screen on a desktop: `python3 tools/preview-ui chooser` or `guard` (test exit password: `test`) |

## 1. Build the installer (your machine)

1. Edit `config/exam.conf`: set the Kaggle URL for each round
   (`ROUND_1=ML round|https://...`, `ROUND_2=Coding round|https://...`).
   Check `config/allowlist.txt`.
2. `bash build-installer.sh` — enter the exam login password and the invigilator exit password.
   Only hashes are written to the bundle.
3. Copy `dist/katalyst-exam-installer/` to the lab machines (USB drive, shared folder, ...).

Rebuild without changing passwords: `bash build-installer.sh --keep-passwords`.

## 2. Install on each lab machine (needs internet)

```
cd <path-to>/katalyst-exam-installer
sudo ./install.sh
```

Takes a few minutes (downloads Firefox ESR from Mozilla's APT repo and `cage`).
It ends with a status report; anything marked `[!!]` needs attention.

## 3. Exam day

1. At the login screen choose **Katalyst Exam**, type the login password.
2. Pick the round (**ML round** / **Coding round**). Both rounds are always
   configured, so nothing changes on the machines between rounds.
3. Student signs in to Kaggle with their own email and password.
4. To end: press **Ctrl+Q** (or close the window) → enter the **exit password** →
   machine returns to the login screen. The next session starts completely fresh.

If a student closes the browser, they just press **Return to exam** (or wait 60 s).
Kaggle autosaves notebooks; tabs are restored.

For a terminal round (`terminal:<name>`), the candidate's answer is
snapshotted to `/var/lib/katalyst-exam/submissions/<user>-<timestamp>-<tag>.txt`
automatically when the 45-minute limit is reached or when the invigilator
authorises an early exit. Collect these after the round with:
```
sudo cat /var/lib/katalyst-exam/submissions/*.txt
```

Every command typed and a process snapshot every 15 s are logged to
`/var/lib/katalyst-exam/monitor/{history.log,process.log}` for post-round
review (e.g. spotting an attempt to launch a browser or network tool).
These are root-only, append-only (`chattr +a`) — the exam user can write
new entries but never read, edit or delete them. Review with:
```
sudo cat /var/lib/katalyst-exam/monitor/history.log
sudo cat /var/lib/katalyst-exam/monitor/process.log
```
To clear them between exam days: `sudo chattr -a <file>` first, then
truncate/remove and let `apply` recreate them.

## Admin commands (on a lab machine)

```
sudo katalyst-exam-admin status
sudo katalyst-exam-admin set-round 1 "ML round" https://www.kaggle.com/competitions/...
sudo katalyst-exam-admin set-round 2 "Coding round" https://www.kaggle.com/competitions/...
sudo katalyst-exam-admin remove-round 2
sudo katalyst-exam-admin edit-allowlist
sudo katalyst-exam-admin set-login-password
sudo katalyst-exam-admin set-exit-password
sudo katalyst-exam-admin usb allow|block
sudo katalyst-exam-admin force-x11 on|off      # black screen / NVIDIA issues
katalyst-exam-admin test-policies              # no sudo: inspect about:policies
```

To change settings on **all** machines: edit `config/` in the installer folder and run
`sudo ./install.sh` again (passwords and settings are updated in place).

## Uninstall

```
sudo ./install.sh --uninstall
```

Deletes the exam user and its files, the session and the policies, and restores
home-folder permissions. Optionally removes Firefox ESR and the Mozilla repo.

## Limits — what this does NOT cover

- **Content inside Kaggle** (public notebooks, discussions): use a private
  competition with unpublished problems.
- **Notebook internet access**: turn the notebook *Internet* setting off, or the
  kernel can call any outside API from Python.
- **Terminal round is not a sandbox**: `restricted-shell` limits which
  *programs* can be run (only `nano`/`python3`), but `python3` itself can run
  arbitrary code (`os.system`, `subprocess`, sockets) — a candidate with
  enough know-how can get a full shell or network access from inside it.
  Accepted risk for a 45-minute round backed by an in-person follow-up, and
  partially mitigated by the command-history + process-snapshot audit log
  (see above) for after-the-fact review.
- **Physical access**: set a BIOS password and disable USB boot, and protect
  GRUB, or anyone can boot into recovery mode.
- **Phones in the room**: invigilation.

## Working on this project from Windows (Git / GitLab)

- `.gitattributes` forces LF line endings for every file. Keep it: Windows
  (CRLF) line endings break the scripts on Linux.
- Windows does not store the executable bit. That is fine: run the scripts as
  `bash build-installer.sh` / `python3 tools/preview-ui`; the build sets all
  permissions inside the package itself.
- Build and test on Linux (e.g. clone the GitLab repo on an Ubuntu machine).
  `dist/` (built installers, password hashes) is git-ignored and must never be
  committed.
