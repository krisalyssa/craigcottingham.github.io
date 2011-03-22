#!/bin/sh
HOME=/home/ec2-user
sleep 20
echo 'running' > $HOME/script-1-output.txt
if [ -f $HOME/script-2-output.txt ];
  echo 'script-2 has run' >> $HOME/script-1-output.txt
else
  echo 'script-2 has not run' >> $HOME/script-1-output.txt
fi
if [ -f $HOME/script-3-output.txt ];
  echo 'script-3 has run' >> $HOME/script-1-output.txt
else
  echo 'script-3 has not run' >> $HOME/script-1-output.txt
fi
