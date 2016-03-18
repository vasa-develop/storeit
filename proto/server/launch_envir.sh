#!/bin/bash

SNAME=storeit
SPATH=$HOME/code/epitech/storeit/proto/server
CLIPATH=$HOME/code/epitech/storeit/proto/client
PORT=7643
FINDER=0


# API documentation:
# reset_db
#   reset the database
#
# run_client [client_name] ["keep-files"]
#   run a client
#
# kill_client [client_name]
#   kill a client process


while getopts "f" opt; do
    case $opt in
      f)
         FINDER=1
         ;;
      \?)
         echo "Invalid option: -$OPTARG" >&2
         ;;
      esac
done

function reset_db {
  cd ./database
  ./init_database.sh &> /dev/null
  cd ..
  log_to_pane "database has been reset"
}

function run_in_tmux {
  tmux split-window -t $SNAME $*
  tmux select-layout tile
  sleep 0.1
  log_to_pane "command $* has been run"
}

function init_client {
  if [ "$1" != "keep-files" ]; then
    rm -rf /tmp/$1
    mkdir /tmp/$1
    cp -r $SPATH/testree /tmp/$1/storeit
  fi

  if [ $FINDER -eq 1 ]; then
    open /tmp/$1/storeit
  fi
}

function run_client {
  init_client $1 $2
  pushd /tmp/$1
  run_in_tmux $CLIPATH/main.py $1 $((PORT++))
  popd
  log_to_pane "client $1 is running"
}

function kill_client {
  kill $(ps aux|grep -v grep | grep "main.py $1" | awk '{print $2}')
  log_to_pane "client $1 has been killed"
}

function log_to_pane {

  BEGIN_COLOR="\e[95m"
  END_COLOR=\e[0m

  echo "\e[95m $(date '+[%H:%M:%S]') \e[0m $1" >> /tmp/panelog.log
}

tmux kill-session -t storeit 2> /dev/null

reset_db

touch /tmp/panelog.log
tmux new-session -d -s $SNAME "tail -f /tmp/panelog.log"
log_to_pane "logging pane..."
run_in_tmux $SPATH/main.py
sleep 0.5 # wait a little bit for the server to start:w
ps cax | grep postgres > /dev/null

if [ $? -eq 0 ]; then
  true
else
    postgres -D /usr/local/var/postgres&
    log_to_pane "running postgres"
fi

source ./simulation.sh