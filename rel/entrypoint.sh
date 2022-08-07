#!/bin/sh

# Give it an extra time to wait for other containers to setup
sleep 5;

/opt/trc/bin/trc eval "Trc.Release.setup_db"
/opt/trc/bin/trc eval "Trc.Release.migrate"
/opt/trc/bin/server