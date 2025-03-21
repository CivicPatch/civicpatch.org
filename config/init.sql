SELECT 'CREATE DATABASE civic_patch_production'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'civic_patch_production')\gexec

SELECT 'CREATE DATABASE civic_patch_production_cache'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'civic_patch_production_cache')\gexec

SELECT 'CREATE DATABASE civic_patch_production_queue'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'civic_patch_production_queue')\gexec

SELECT 'CREATE DATABASE civic_patch_production_cable'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'civic_patch_production_cable')\gexec

