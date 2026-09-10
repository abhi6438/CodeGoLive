-- Module 7 topics for dev-quickstart


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '7'),
  '700',
  'dev-qs-prereqs-check',
  'Prerequisites Check',
  'What you need before installing anything',
  'A quick checklist to verify your OS, permissions, and existing tools before you touch an installer.',
  '# Prerequisites Check

Before installing any tools, confirm your machine is ready.

## Operating System

| OS | Supported |
|----|-----------|
| Windows 10/11 (64-bit) | ✅ |
| macOS 12+ (Intel or Apple Silicon) | ✅ |
| Ubuntu 20.04+ / Debian | ✅ |

> **Windows users:** use PowerShell or Windows Terminal — not the old CMD prompt.

## Check if Node.js is already installed

```bash
node --version
npm --version
```

If both return a version number (Node 18+ is ideal), you can skip the Node install topic.

## Check if Git is installed

```bash
git --version
```

If it says `git version 2.x.x`, you''re fine. Otherwise install from [git-scm.com](https://git-scm.com).

## Check if Java is installed

```bash
java --version
javac --version
```

You need **Java 17 or 21** (LTS) for CAP Java projects. OpenJDK is fine.

## Check if Maven is installed

```bash
mvn --version
```

Maven 3.8+ is required for CAP Java. If missing, install it in the CAP Java setup module.

## Check available disk space

You''ll need at least **5 GB free** for all tools, SDKs, and project files.

```bash
# macOS / Linux
df -h ~

# Windows PowerShell
Get-PSDrive C
```

## Summary checklist

- [ ] 64-bit OS (Windows 10/11, macOS 12+, or Ubuntu 20.04+)
- [ ] Administrator / sudo access
- [ ] At least 5 GB free disk space
- [ ] Stable internet connection
- [ ] Git installed (or will install)

Once your checklist is green, move to the next topic.
',
  0,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '7'),
  '701',
  'dev-qs-nodejs-install',
  'Install Node.js & npm',
  'Install the correct LTS version and verify it works',
  'Install Node.js LTS using nvm (recommended) or the official installer, and confirm npm is working.',
  '# Install Node.js & npm

Almost every tool in this course (SAPUI5, CAP Node.js, CF CLI) depends on Node.js.

## Option A — nvm (recommended, lets you switch versions easily)

### macOS / Linux

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload your shell
source ~/.bashrc   # or ~/.zshrc on macOS

# Install the latest LTS
nvm install --lts

# Set it as default
nvm alias default node
```

### Windows — use nvm-windows

Download the installer from [github.com/coreybutler/nvm-windows/releases](https://github.com/coreybutler/nvm-windows/releases), then:

```powershell
nvm install lts
nvm use lts
```

## Option B — Official installer

Go to [nodejs.org](https://nodejs.org) and download the **LTS** version for your OS. Run the installer and accept defaults.

## Verify

```bash
node --version   # should print v20.x.x or v22.x.x
npm --version    # should print 10.x.x or higher
```

## Update npm to latest

```bash
npm install -g npm@latest
```

## Install useful global packages you will need later

```bash
npm install -g @sap/cds-dk @ui5/cli mbt
```

> These three packages cover CAP development, SAPUI5 tooling, and MTA build. Installing them now saves time in later modules.

## Troubleshoot: `EACCES permission denied` on macOS/Linux

This happens when npm tries to write to a system folder. Fix with nvm (Option A) — it installs Node in your home directory so no `sudo` is ever needed.
',
  1,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '7'),
  '702',
  'dev-qs-vscode-setup',
  'VS Code Setup & SAP Extensions',
  'Install VS Code and the extensions that make SAP development fast',
  'Download VS Code, install the essential SAP and general-purpose extensions, and configure key settings.',
  '# VS Code Setup & SAP Extensions

VS Code is the standard editor for SAPUI5, CAP Node.js, and CAP Java development.

## Download & Install

Go to [code.visualstudio.com](https://code.visualstudio.com) and install the **Stable** build for your OS.

## Essential Extensions

Open VS Code, press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS), and install these:

### SAP-specific

| Extension | Publisher | Why |
|-----------|-----------|-----|
| **SAP Fiori Tools - Application Generator** | SAP | Generate SAPUI5 apps in seconds |
| **SAP Fiori Tools - Extension Pack** | SAP | Adds page map, service modeler, guided dev |
| **SAP CDS Language Support** | SAP | Syntax highlighting and autocomplete for .cds files |
| **SAP Fiori** | SAP | Preview Fiori apps locally |

### General (highly recommended)

| Extension | Publisher | Why |
|-----------|-----------|-----|
| **ESLint** | Microsoft | Catch JS/TS errors as you type |
| **Prettier** | Prettier | Auto-format on save |
| **GitLens** | GitKraken | Inline git blame and history |
| **REST Client** | Huachao Mao | Test your CAP OData endpoints from inside VS Code |
| **XML** | Red Hat | Format and validate `manifest.xml`, `xs-app.json` |

### For CAP Java only

| Extension | Publisher | Why |
|-----------|-----------|-----|
| **Extension Pack for Java** | Microsoft | Java language server, debugger, Maven support |
| **Spring Boot Extension Pack** | VMware | Spring Boot dashboard, live beans view |

## Key settings to configure

Open settings with `Ctrl+,` and add to `settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "files.autoSave": "onFocusChange",
  "editor.fontSize": 14,
  "terminal.integrated.defaultProfile.windows": "PowerShell"
}
```

## Verify SAP Fiori tools are working

1. Press `Ctrl+Shift+P` → type **Fiori: Open Application Generator**
2. If the wizard opens, you''re ready for the SAPUI5 module.
',
  2,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '7'),
  '703',
  'dev-qs-cf-btp-cli',
  'Cloud Foundry CLI & BTP CLI',
  'Install the two CLIs needed to deploy and manage BTP apps',
  'Install the cf CLI (v8) and the BTP CLI, log in, and verify both tools are talking to your BTP account.',
  '# Cloud Foundry CLI & BTP CLI

You need two command-line tools to deploy applications to SAP BTP:

| Tool | What it does |
|------|-------------|
| **cf CLI** | Deploy, scale, and manage apps in a Cloud Foundry space |
| **btp CLI** | Manage BTP global account resources (subaccounts, service instances, entitlements) |

---

## Install the CF CLI (v8)

### macOS

```bash
brew install cloudfoundry/tap/cf-cli@8
```

### Windows (PowerShell)

Download the installer from [github.com/cloudfoundry/cli/releases](https://github.com/cloudfoundry/cli/releases) — pick the `cf8-installer-windows64.zip`.

### Linux (Debian/Ubuntu)

```bash
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt update && sudo apt install cf8-cli
```

### Verify

```bash
cf --version
# CF CLI version 8.x.x
```

---

## Log in to Cloud Foundry

```bash
cf login -a https://api.cf.eu10.hana.ondemand.com
# Replace eu10 with your BTP region (us10, ap21, etc.)
```

Enter your BTP email and password. Select your org and space.

```bash
cf target   # shows current org/space
```

---

## Install the BTP CLI

Download from [tools.hana.ondemand.com](https://tools.hana.ondemand.com/#cloud) → **SAP BTP command line interface**.

Or on macOS/Linux:

```bash
# Check https://tools.hana.ondemand.com for the latest URL
curl -L https://tools.hana.ondemand.com/additional/btp-cli-linux-amd64-2.x.x.tar.gz | tar xz
sudo mv btp /usr/local/bin/
```

### Verify

```bash
btp --version
btp login
# Follow the browser login prompt
```

---

## Quick reference — commands you will use constantly

```bash
cf apps                     # list deployed apps in current space
cf logs <app-name> --recent # view recent app logs
cf env <app-name>           # view environment variables
cf restage <app-name>       # rebuild app image after env change
cf push                     # deploy from current directory
```
',
  3,
  'published'
);
