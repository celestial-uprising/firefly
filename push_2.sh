#!/bin/bash

for i in $( ls cf/new/2/ ) ; do podman push localhost/firefly:${i} ghcr.io/celestial-uprising/firefly:${i} ; done
