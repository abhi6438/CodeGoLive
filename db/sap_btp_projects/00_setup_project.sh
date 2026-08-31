#!/bin/bash
# SAP BTP Topic 0: Setup Project
# Run this inside SAP Business Application Studio terminal

# 1. Install generator (if not already installed)
npm install -g yo @sap/generator-fiori-freestyle

# 2. Scaffold app
yo @sap/fiori-freestyle --skip-install \
  --template freestyle \
  --datasource none \
  --moduleName myapp \
  --namespace com.example \
  --ui5Theme sap_horizon

# 3. Install dependencies
cd myapp && npm install

# 4. Start dev server
npm start
# => Open http://localhost:8080 in the browser preview
