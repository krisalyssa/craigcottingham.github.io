#!/bin/sh
HOME=/home/ec2-user
sleep 10
echo 'running' > $HOME/script-2-output.txt
if [ -f $HOME/script-1-output.txt ]
  echo 'script-1 has run' >> $HOME/script-2-output.txt
else
  echo 'script-1 has not run' >> $HOME/script-2-output.txt
fi
if [ -f $HOME/script-3-output.txt ]
  echo 'script-3 has run' >> $HOME/script-2-output.txt
else
  echo 'script-3 has not run' >> $HOME/script-2-output.txt
fi
