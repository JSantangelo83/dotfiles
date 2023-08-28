#!/bin/bash

# Accepting the vpn ssh incoming connection
sudo ufw allow from 10.243.249.178 to 10.243.246.143 port 22;

# Denying anything else
sudo ufw default deny incoming;

sudo ufw reload;
