#!/bin/bash

###############################
#  launch_env.sh (modified)   #
###############################

# Disable MSYS (Git‐Bash) automatic path‐conversion, so that any "/mnt/…" paths
# you pass to docker run come through literally. If you omit this line under
# Git‐Bash/MSYS, Docker would see "/mnt/yaetos_jobs" as "C:/Program Files/Git/mnt/yaetos_jobs",
# which doesn’t exist.
export MSYS_NO_PATHCONV=1

# Script to setup the environment for yaetos. It needs to be executed from the repo root folder.
# Before using:
# - make sure awscli is configured on your host (i.e. you have ~/.aws/{config,credentials}, e.g. via "aws configure").
# - If you don’t want AWS access at all, you can comment out the "-v $HOME/.aws:/root/.aws" lines.
#
# Usage:
# - "./launch_env.sh"      -> no Docker container (runs local / pandas jobs or native AWS runs).
# - "./launch_env.sh 1"    -> opens an interactive container shell (useful for Spark/pyspark commands).
# - "./launch_env.sh 2"    -> opens Jupyter Lab inside the container (viewable at http://localhost:8888).
# - "./launch_env.sh 3 <cmd>" -> runs the given <cmd> inside a one‐off container (for non‐interactive job runs).
# - "./launch_env.sh 4 <cmd>" -> runs <cmd> directly on the host (no Docker).
#
# (Make sure AWS profiles exist in your host ~/.aws so that inside Docker they appear under /root/.aws.)

yaetos_jobs_home="$PWD"   # The folder containing your Yaetos repo (where launch_env.sh lives).

run_mode="$1"  # Acceptable values:
               # 1 = docker bash
               # 2 = docker jupyter
               # 3 = execute a job in docker
               # 4 = execute a command natively on host

if [[ "$run_mode" = "1" ]]; then
  echo "Starting Docker (interactive bash shell)..."
  docker build -t pyspark_container .    # Build the image (tags it as pyspark_container)
  docker run -it \
    -p 4040:4040 -p 8080:8080 -p 8081:8081 -p 8888:8888 \
    -v "$yaetos_jobs_home":"/mnt/yaetos_jobs" \
    -v "$HOME/.aws":"/root/.aws" \
    -h spark \
    -w "/mnt/yaetos_jobs" \
    pyspark_container \
    bash

elif [[ "$run_mode" = "2" ]]; then
  echo "Starting Docker (Jupyter Lab)..."
  docker build -t pyspark_container .
  docker run -it \
    -p 4040:4040 -p 8080:8080 -p 8081:8081 -p 8888:8888 \
    -v "$yaetos_jobs_home":"/mnt/yaetos_jobs" \
    -v "$HOME/.aws":"/root/.aws" \
    -h spark \
    -w "/mnt/yaetos_jobs" \
    pyspark_container \
    jupyter lab --ip 0.0.0.0 --port 8888 --no-browser --allow-root

elif [[ "$run_mode" = "3" ]]; then
  cmd_str="${@:2}"
  echo "Launching one‐off job in Docker: $cmd_str"
  docker build -t pyspark_container .
  docker run -it \
    -p 4040:4040 -p 8080:8080 -p 8081:8081 -p 8888:8888 \
    -v "$yaetos_jobs_home":"/mnt/yaetos_jobs" \
    -v "$HOME/.aws":"/root/.aws" \
    -h spark \
    -w "/mnt/yaetos_jobs" \
    pyspark_container \
    bash -lc "$cmd_str"

elif [[ "$run_mode" = "4" ]]; then
  shift
  cmd_str="$*"
  echo "Executing command on the host: $cmd_str"
  eval "$cmd_str"

else
  echo "Usage:"
  echo "  $0                # run no‐docker local/pandas or native AWS jobs"
  echo "  $0 1              # interactive Docker bash"
  echo "  $0 2              # interactive Docker Jupyter Lab"
  echo "  $0 3 <cmd>        # run <cmd> in Docker (one‐off; e.g. yaetos job)"
  echo "  $0 4 <cmd>        # run <cmd> on host (no Docker)"
  echo
  echo "Examples:"
  echo "  $0 1                     # pop into container shell"
  echo "  $0 2                     # pop into Jupyter Lab inside container"
  echo "  $0 3 \"yaetos run ex0\"    # run 'yaetos run ex0' inside a fresh container"
  echo "  $0 4 \"yaetos run ex0\"    # run 'yaetos run ex0' on the host machine"
fi
