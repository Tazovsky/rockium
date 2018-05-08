#!/bin/bash
CORE_DIR=$1
echo "setwd('$CORE_DIR')" >> $(R RHOME)/etc/Rprofile.site