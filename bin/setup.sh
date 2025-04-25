#! /bin/bash

## npm install express helmet cors express-rate-limit hpp csurf winston morgan pg sequelize passport jsonwebtoken bcryptjs dotenv pm2
## npm install --save-dev jest supertest eslint prettier nodemon swagger-ui-express swagger-jsdoc
## /bin/setup.sh, client, common, server

sudo apt update

#!/bin/bash

PG_HOST="db"
PG_USER="codespace"
PG_PASSWORD="password"
PG_DB_DEFAULT="mydatabase"
TARGET_USER="toor"
TARGET_PASSWORD="toorpwd"
TARGET_DB="invoice"

# To be run from 'app' container
check_psql_client() {
    if ! command -v psql &> /dev/null; then
        echo "PostgreSQL client (psql) is not found."
        echo "Please ensure 'postgresql-client' is installed in your app service's Dockerfile."
        exit 1
    else
        echo "PostgreSQL client (psql) is available."
    fi
}

# To be run from 'app' container
check_and_setup_postgres_user_db() {
    echo "Checking for PostgreSQL user '${TARGET_USER}' and database '${TARGET_DB}'..."

    export PGPASSWORD="${PG_PASSWORD}"

    if psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c '\l' &> /dev/null; then
        echo "Successfully connected to PostgreSQL as user '${PG_USER}' on ${PG_HOST}."

        if ! psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c '\du' | grep -q " ${TARGET_USER} "; then
            echo "PostgreSQL user '${TARGET_USER}' not found. Creating user..."
            psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c "CREATE USER ${TARGET_USER} WITH ENCRYPTED PASSWORD '${TARGET_PASSWORD}';"
            echo "PostgreSQL user '${TARGET_USER}' created."
        else
            echo "PostgreSQL user '${TARGET_USER}' already exists."
        fi

        if ! psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c '\l' | grep -q " ${TARGET_DB} "; then
            echo "PostgreSQL database '${TARGET_DB}' not found. Creating database..."
            psql -h "${PG_HOST}" -U "${PG_USER}" -d "${PG_DB_DEFAULT}" -c "CREATE DATABASE ${TARGET_DB};"
            echo "PostgreSQL database '${TARGET_DB}' created."
        else
            echo "PostgreSQL database '${TARGET_DB}' already exists."
        fi

        echo "Granting privileges to user '${TARGET_USER}' on database '${TARGET_DB}'..."
        if psql -h "${PG_HOST}" -U "${PG_USER}" -d "${TARGET_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${TARGET_DB} TO ${TARGET_USER};"; then
            echo "Privileges granted."
        else
             echo "Failed to grant privileges. Ensure database '${TARGET_DB}' exists and user '${PG_USER}' has necessary permissions."
        fi


    else
        echo "Could not connect to PostgreSQL as user '${PG_USER}' on ${PG_HOST}."
        echo "Please ensure the 'db' service is running and accessible from the 'app' service."
        exit 1
    fi

    unset PGPASSWORD
}

check_node() {
    if ! command -v node &> /dev/null; then
        echo "Node.js is not installed. Installing Node.js LTS..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
    else
        echo "Node.js is already installed."
    fi
}

cd "$(dirname "$0")/../server" || { echo "Directory ../server does not exist. Exiting."; exit 1; }

check_express() {
    if [ ! -f "app.js" ] || [ ! -d "routes" ]; then
        echo "Express is not set up in the server directory. Setting up Express..."
        npx express-generator --view=ejs
    else
        echo "Express is already set up in the server directory."
    fi
}


install_prod_packages() {
    echo "Installing production packages..."
    npm install helmet cors express-rate-limit hpp csurf winston morgan pg sequelize passport jsonwebtoken accesscontrol compression bcryptjs dotenv pm2
}

install_dev_packages() {
    echo "Installing development packages..."
    npm install --save-dev jest supertest eslint prettier nodemon swagger-ui-express swagger-jsdoc
}

check_node
check_express
install_prod_packages
install_dev_packages