#!/bin/bash
REPO=/home/rstudio/MP26

# Fix ownership in case of permission issues
chown -R rstudio:rstudio "$REPO"
chmod -R g+w "$REPO"

# Pull as rstudio user
sudo -u rstudio git -C "$REPO" pull