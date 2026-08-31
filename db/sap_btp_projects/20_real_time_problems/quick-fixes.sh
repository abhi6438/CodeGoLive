#!/bin/bash
# Quick diagnostic commands for common BTP errors

echo "=== CF App Status ==="
cf apps

echo "=== Recent Logs ==="
cf logs bookshop-srv --recent | tail -50

echo "=== Bound Services ==="
cf services

echo "=== App Environment ==="
cf env bookshop-srv

echo "=== CAP local check ==="
cds compile --to hana db/schema.cds 2>&1 | head -20
