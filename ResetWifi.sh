#!/bin/bash
# The following script should be run when the WiFi connection gets stuck.
# Created by José Ángel Martín Baos

sudo systemctl restart network-manager.service
