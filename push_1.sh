#!/bin/bash

for i in $( ls cf/new/1/ ) ; do podman push localhost/firefly:${i} ghcr.io/celestial-uprising/firefly:${i} ; done
