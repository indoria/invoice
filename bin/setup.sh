#!/bin/bash

set -e

echo "Running postCreateCommand setup script..."

PG_HOST="db"
PG_USER="codespace"
PG_PASSWORD="password"
PG_DB_DEFAULT="mydatabase"
TARGET_USER="toor"
TARGET_PASSWORD="toorpwd"
TARGET_DB="invoice"

SERVER_DIR="server"
CLIENT_DIR="client"
COMMON_DIR="common"
BIN_DATA_DIR="bin/data"

echo "Creating project directories: ${SERVER_DIR}, ${CLIENT_DIR}, ${COMMON_DIR}..."
mkdir -p "${SERVER_DIR}" "${CLIENT_DIR}" "${COMMON_DIR}"
echo "Directories created or already exist."

check_psql_client() {
    echo "Checking for PostgreSQL client (psql)..."
    if ! command -v psql &> /dev/null; then
        echo "PostgreSQL client (psql) is not found."
        echo "Please ensure 'postgresql-client' is installed in your app service's Dockerfile."
        exit 1
    else
        echo "PostgreSQL client (psql) is available."
    fi
}

check_and_setup_postgres_user_db() {
    echo "Checking for PostgreSQL user '${TARGET_USER}' and database '${TARGET_DB}'..."

    export PGPASSWORD="${PG_PASSWORD}"

    echo "Waiting for PostgreSQL service ('db') to be ready..."
    until psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c '\q' 2>/dev/null; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
    done
    echo "PostgreSQL service is ready."

    if ! psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -tAc "SELECT 1 FROM pg_user WHERE usename = '${TARGET_USER}'" | grep -q 1; then
        echo "PostgreSQL user '${TARGET_USER}' not found. Creating user..."
        psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c "CREATE USER ${TARGET_USER} WITH ENCRYPTED PASSWORD '${TARGET_PASSWORD}';"
        echo "PostgreSQL user '${TARGET_USER}' created."
    else
        echo "PostgreSQL user '${TARGET_USER}' already exists."
    fi

    if ! psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${TARGET_DB}'" | grep -q 1; then
        echo "PostgreSQL database '${TARGET_DB}' not found. Creating database..."
        psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c "CREATE DATABASE ${TARGET_DB};"
        echo "PostgreSQL database '${TARGET_DB}' created."
    else
        echo "PostgreSQL database '${TARGET_DB}' already exists."
    fi

    echo "Granting privileges to user '${TARGET_USER}' on database '${TARGET_DB}'..."
    if ! psql -h "${PG_HOST}" -U "${PG_USER}" -d "${TARGET_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_grant WHERE objid = (SELECT oid FROM pg_database WHERE datname = '${TARGET_DB}') AND grantee = (SELECT oid FROM pg_user WHERE usename = '${TARGET_USER}')" | grep -q 1; then
         if psql -h "${PG_HOST}" -U "${PG_USER}" -d "${TARGET_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${TARGET_DB} TO ${TARGET_USER};"; then
            echo "Privileges granted."
         else
            echo "Failed to grant privileges. Ensure database '${TARGET_DB}' exists and user '${PG_USER}' has necessary permissions."
         fi
    else
        echo "Privileges already granted."
    fi

    unset PGPASSWORD
}

check_node() {
    echo "Checking for Node.js..."
    if ! command -v node &> /dev/null; then
        echo "Node.js is not found."
        echo "Please ensure 'nodejs' is installed in your app service's Dockerfile."
        exit 1
    else
        echo "Node.js is available."
    fi
}

check_and_setup_express() {
    echo "Checking Express setup in ${SERVER_DIR} directory..."
    pushd "${SERVER_DIR}" > /dev/null || { echo "Error navigating to ${SERVER_DIR}. Exiting."; exit 1; }

    if [ ! -f "package.json" ]; then
        echo "Express package.json not found. Setting up Express using express-generator..."
        npx express-generator --view=ejs ../server --no-install
        echo "Express setup complete (files generated)."
    else
        echo "Express package.json already exists. Skipping express-generator."
    fi

    popd > /dev/null
}

install_base_packages() {
    echo "Installing base npm packages in ${SERVER_DIR}..."
    pushd "${SERVER_DIR}" > /dev/null || { echo "Error navigating to ${SERVER_DIR}. Exiting."; exit 1; }

    if [ -f "package.json" ]; then
        npm install
        echo "Base npm packages installed."
    else
        echo "package.json not found in ${SERVER_DIR}. Skipping base package installation."
    fi

    popd > /dev/null
}

echo "Moving files from ${BIN_DATA_DIR} to ${SERVER_DIR}..."
mv -f "${BIN_DATA_DIR}/gitignore.txt" "${SERVER_DIR}/.gitignore" || { echo "Warning: Could not move ${BIN_DATA_DIR}/gitignore.txt. File might not exist."; }
mv -f "${BIN_DATA_DIR}/app.js" "${SERVER_DIR}/" || { echo "Warning: Could not move ${BIN_DATA_DIR}/app.js. File might not exist."; }
echo "Files moved."

install_prod_packages() {
    echo "Installing production packages in ${SERVER_DIR}..."
     pushd "${SERVER_DIR}" > /dev/null || { echo "Error navigating to ${SERVER_DIR}. Exiting."; exit 1; }

    if [ -f "package.json" ]; then
        npm install helmet cors express-rate-limit hpp csurf winston morgan pg sequelize passport jsonwebtoken accesscontrol compression bcryptjs dotenv pm2
        echo "Production packages installed."
    else
        echo "package.json not found in ${SERVER_DIR}. Skipping production package installation."
    fi

    popd > /dev/null
}

install_dev_packages() {
    echo "Installing development packages in ${SERVER_DIR}..."
     pushd "${SERVER_DIR}" > /dev/null || { echo "Error navigating to ${SERVER_DIR}. Exiting."; exit 1; }

    if [ -f "package.json" ]; then
        npm install --save-dev jest supertest eslint prettier nodemon swagger-ui-express swagger-jsdoc
        echo "Development packages installed."
    else
        echo "package.json not found in ${SERVER_DIR}. Skipping development package installation."
    fi

    popd > /dev/null
}

check_psql_client
check_and_setup_postgres_user_db
check_node
check_and_setup_express
install_base_packages
install_prod_packages
install_dev_packages

echo "postCreateCommand setup script finished."
