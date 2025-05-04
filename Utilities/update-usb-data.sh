#!/bin/bash

if [ -d ../Resources ]; then
    curl http://www.usb.org/developers/tools/comp_dump > ../Resources/usb-vendors.txt
else
    curl http://www.usb.org/developers/tools/comp_dump > Resources/usb-vendors.txt
fi
