# Capstone Part 4

## Goal
Secure & Deploy — XSUAA, App Router, MTA, Cloud Foundry

## Checklist
- [ ] CDS data model defined in db/schema.cds
- [ ] Service exposed in srv/<service>.cds  
- [ ] Seed CSV in db/data/<namespace>-<Entity>.csv
- [ ] UI5 views created for each screen
- [ ] Controller logic wired to OData V4 binding
- [ ] Validation + error handling in place
- [ ] mta.yaml configured for deployment

## Test Commands
```bash
cds watch          # run CAP backend
npm start          # run UI5 frontend
cds build --production  # production build check
mbt build               # MTA archive
cf deploy *.mtar         # deploy to BTP
```
