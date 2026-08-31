#!/bin/bash
# Deploy SAP BTP app

# 1. Build CAP for production
cd bookshop && cds build --production && cd ..

# 2. Build MTA archive
mbt build

# 3. Login to Cloud Foundry
cf login -a https://api.cf.us10.hana.ondemand.com

# 4. Deploy
cf deploy mta_archives/bookshop_1.0.0.mtar

# 5. Verify
cf apps
echo "Done! Check the App Router URL to access the app."
