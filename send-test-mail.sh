#!/usr/bin/env bash

mailsend-go \
-smtp ***REMOVED*** -port 587 \
auth -user ***REMOVED*** -pass ***REMOVED*** \
-from ***REMOVED*** -to ***REMOVED*** \
-sub "Manage data in Docker" \
body -msg "https://docs.docker.com/storage/"
