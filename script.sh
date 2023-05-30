#!/bin/bash

## Install Nodejs 14.x
install_node() {
    curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt install -y nodejs
}

## Clone_Repo

git_repo() {
    git clone https://github.com/omarmohsen/pern-stack-example.git
}

# Make IP config.file for the local machine to use static address 

IP_Config() { 
    sudo tee /etc/netplan/02-new-conf.yaml <<EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens33:
      dhcp4: no
      addresses: [192.168.60.128/24]
      routes:
        - to: default
          via: 192.168.60.255
      nameservers:
          addresses: [192.168.1.1,172.20.10.1]
EOF
    sudo netplan apply
    sudo systemctl restart NetworkManager
}


add_user_node() {
    sudo useradd node
}

retrieve_IP() {
    IP_ADDRESS=$(ip -4 addr show ens33 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
}

## Installing Postgresql 

installing_postgresql(){
    sudo apt-get update
    sudo apt-get install postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sudo -u postgres psql -c "CREATE USER node WITH PASSWORD 'node2023';"
    sudo -u postgres createdb demo_db
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE demo_db TO node;"
}


## Run UI tests 
ui_tests() {
    cd pern-stack-example/ui 
    sudo apt install npm
    npm run test 
}


build_UI() {
    npm install
    npm run build
}

## modify the ENVIRONMENT to add 'demo' environment within the if statement

add_env() {
    cd ..
    cd api
    npm install webpack
    npm audit fix
 sed -i "s/module/else if (environment === 'demo') {\n  console.log('this is demo env')\n  ENVIRONMENT_VARIABLES = {\n    'process.env.HOST': JSON.stringify('$IP_ADDRESS'),\n    'process.env.USER': JSON.stringify('node'),\n    'process.env.DB': JSON.stringify('demo_db'),\n    'process.env.DIALECT': JSON.stringify('postgres'),\n    'process.env.PORT': JSON.stringify('4050'),\n    'process.env.PG_CONNECTION_STR': JSON.stringify('postgres:\/\/node:node@localhost:5432\/node')\n  };\n}\n\n&/" webpack.config.js
    ENVIRONMENT=demo npm run build
}

## start the application

deploy_app() {
    cd ..
    
    cp -r api/dist/* .
    cp api/swagger.css .
    npm install pg
    node api.bundle.js
}


install_node

git_repo

IP_Config

add_user_node

retrieve_IP

installing_postgresql

ui_tests

build_UI

add_env

deploy_app

