# BTP Destinations

## Create destination in BTP Cockpit
Name: MyBackend
Type: HTTP
URL: https://your-cap-app.cfapps.us10.hana.ondemand.com
Authentication: NoAuthentication
ProxyType: Internet
Additional Property: HTML5.DynamicDestination = true

## Test locally
export destinations='[{"name":"MyBackend","url":"http://localhost:4004"}]'
node node_modules/@sap/approuter/approuter.js
