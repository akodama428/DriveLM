#!/bin/bash

# This script starts PDM-Lite and the CARLA simulator on a local machine

# Make sure any previously started Carla simulator instance is stopped
# Sometimes calling pkill Carla only once is not enough.
pkill Carla
pkill Carla
pkill Carla

term() {
  echo "Terminated Carla"
  pkill Carla
  pkill Carla
  pkill Carla
  exit 1
}
trap term SIGINT

export CARLA_ROOT="/home/atsushi/DriveLM/pdm_lite/carla/CARLA_Leaderboard_20"
export WORK_DIR="/home/atsushi/DriveLM/pdm_lite"
export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI
export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI/carla
export SCENARIO_RUNNER_ROOT=${WORK_DIR}/scenario_runner
export LEADERBOARD_ROOT=${WORK_DIR}/leaderboard
export PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/":"${SCENARIO_RUNNER_ROOT}":"${LEADERBOARD_ROOT}":${PYTHONPATH}

# carla
export CARLA_SERVER=${CARLA_ROOT}/CarlaUE4.sh
export REPETITIONS=1
export DEBUG_CHALLENGE=1
# export PTH_ROUTE=${WORK_DIR}/leaderboard/data/routes_devtest
export PTH_ROUTE=/home/atsushi/carla_garage/Bench2Drive/leaderboard/data/bench2drive220_0_pdm_lite_traj
export IS_BENCH2DRIVE=1

# Function to handle errors
handle_error() {
  pkill Carla
  exit 1
}

# Set up trap to call handle_error on ERR signal
trap 'handle_error' ERR

# Start the carla server
export PORT=$((RANDOM % (40000 - 2000 + 1) + 2000)) # use a random port
sh ${CARLA_SERVER} -carla-streaming-port=0 -carla-rpc-port=${PORT} &
sleep 20 # on a fast computer this can be reduced to sth. like 6 seconds

echo 'Port' $PORT

export TEAM_AGENT=${WORK_DIR}/team_code/data_agent.py # use autopilot.py here to only run the expert without data generation
export CHALLENGE_TRACK_CODENAME=MAP
export ROUTES=${PTH_ROUTE}.xml
export TM_PORT=$((PORT + 3))

export CHECKPOINT_ENDPOINT=${PTH_ROUTE}.json
export TEAM_CONFIG=${PTH_ROUTE}.xml
export PTH_LOG='log_root/logs_2'
export RESUME=1
export DATAGEN=1
export SAVE_PATH='log_root/logs_2'
export TM_SEED=0

# Start the actual evaluation / data generation
CUDA_VISIBLE_DEVICES=0 python leaderboard/leaderboard/leaderboard_evaluator_local.py --port=${PORT} --traffic-manager-port=${TM_PORT} --routes=${ROUTES} --repetitions=${REPETITIONS} --track=${CHALLENGE_TRACK_CODENAME} --checkpoint=${CHECKPOINT_ENDPOINT} --agent=${TEAM_AGENT} --agent-config=${TEAM_CONFIG} --debug=0 --resume=${RESUME} --timeout=2000 --traffic-manager-seed=${TM_SEED}

# Kill the Carla server afterwards
pkill Carla
