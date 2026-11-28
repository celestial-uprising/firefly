#!/bin/bash

for i in $( ls cf/new/2/ ) ; do podman build --no-cache -t firefly:${i} -f cf/new/2/${i} . ; done
