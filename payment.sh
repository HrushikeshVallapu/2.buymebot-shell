#!/bin/bash

source ./common.sh
app_name=payment

check_root
app_setup
python3_setup
systemd_setup
print_time