#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <server>"
    exit 1
fi

# Assign the argument to a variable
SERVER=$1

# Step 1: Install dependencies
npm install

# Step 2: Execute the SQL file to create the database and tables
sqlcmd -S $SERVER -E -i ./sql/database/InitDatabase.SQL

# Step 3: Execute the SQL file to load data
sqlcmd -S $SERVER -d QUANLI_VCS -E -i ./sql/database/CreateData.sql

# Step 4: Update the config.json file in the src/config/ directory
# Note: This step requires jq to be installed for JSON processing.

jq --arg server "$SERVER" \
   '.start.server = $server' \
   ./src/config/config.json > ./src/config/config.tmp.json && mv ./src/config/config.tmp.json ./src/config/config.json

# Step 5: Install specific versions of Python dependencies
pip install flask==2.0.3 joblib==1.1.0

# Step 6: Start the AI prediction function
start cmd /k python app.py

# Step 7: Start the application
npm start &