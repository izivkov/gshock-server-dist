#!/bin/bash

# This script runs all setup scripts in order.

. ./setup.sh
. ./setup-boot.sh
. ./setup-display.sh
. ./gshock-updater.sh
. ./enable-spi.sh
