#!/bin/sh
HOME=/home/ec2-user
echo 'running' > $HOME/script-3-output.txt
if [ -f $HOME/script-1-output.txt ]; then
  echo 'script-1 has run' >> $HOME/script-3-output.txt
else
  echo 'script-1 has not run' >> $HOME/script-3-output.txt
fi
if [ -f $HOME/script-2-output.txt ]; then
  echo 'script-2 has run' >> $HOME/script-3-output.txt
else
  echo 'script-2 has not run' >> $HOME/script-3-output.txt
fi
