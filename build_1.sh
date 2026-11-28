#!/bin/bash

for i in $( ls cf/new/1/ ) ; do podman build --no-cache -t firefly:${i} -f cf/new/1/${i} . ; done
