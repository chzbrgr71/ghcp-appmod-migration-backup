#!/bin/bash

# Script to configure PostgreSQL for Azure Managed Identity access

set -e

echo "==================================="
echo "PostgreSQL Managed Identity Setup"
echo "==================================="

# Variables
RESOURCE_GROUP="briar-aks"
SERVER_NAME="db-petclinic14db"
DATABASE_NAME="petclinic"
MI_NAME="mi-petclinic"
SERVER_FQDN="db-petclinic14db.postgres.database.azure.com"

echo ""
echo "Step 1: Getting Azure AD access token..."
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

if [ -z "$PGPASSWORD" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi
echo "✅ Access token obtained"

echo ""
echo "Step 2: Connecting to PostgreSQL and setting up managed identity..."

# Create SQL commands file
cat > /tmp/setup_mi.sql <<EOF
-- Set validation mode
SET aad_validate_oids_in_tenant = off;

-- List existing principals
SELECT * FROM pgaadauth_list_principals(true);

-- Create the managed identity user (if not exists)
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'mi-petclinic') THEN
        PERFORM pgaadauth_create_principal('${MI_NAME}', false, false);
        RAISE NOTICE 'Created user ${MI_NAME}';
    ELSE
        RAISE NOTICE 'User ${MI_NAME} already exists';
    END IF;
END
\$\$;

-- Grant database permissions
GRANT ALL PRIVILEGES ON DATABASE ${DATABASE_NAME} TO "${MI_NAME}";

-- Connect to the petclinic database to grant schema permissions
\c ${DATABASE_NAME}

-- Grant schema permissions
GRANT ALL PRIVILEGES ON SCHEMA public TO "${MI_NAME}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "${MI_NAME}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "${MI_NAME}";

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "${MI_NAME}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "${MI_NAME}";

-- Verify the setup
\du "${MI_NAME}"

SELECT 'Setup completed successfully!' as status;
EOF

echo ""
echo "Executing SQL commands..."

# Get current Azure user email
ADMIN_USER=$(az account show --query user.name -o tsv)

# Connect and execute
psql "host=${SERVER_FQDN} port=5432 dbname=postgres user=${ADMIN_USER} sslmode=require" \
     -f /tmp/setup_mi.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Managed identity setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. The managed identity '${MI_NAME}' now has access to the '${DATABASE_NAME}' database"
    echo "2. You can now restart the application pods:"
    echo "   kubectl rollout restart deployment/petclinic -n petclinic"
else
    echo ""
    echo "❌ Failed to set up managed identity"
    exit 1
fi

# Cleanup
rm -f /tmp/setup_mi.sql
