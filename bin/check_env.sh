#!/bin/bash

DIR=$(dirname "$0")
. "$DIR"/.color
. ./.amv_lint.env
ENV_USING_CHECKING_DIRS=$1
DEBUG_MODE=$2

checking_env_lines () {
  sh "$DIR"/utilities.sh count_file_line .env
  env_file_line=$?
  sh "$DIR"/utilities.sh count_file_line .env.example
  env_example_file_line=$?
  if [ "$env_file_line"  != "$env_example_file_line" ]; then
    echo -e "${RED}[✗] Not match: You cannot commit this change.${RESET_COLOR}" > "$CHECKING_ERROR_LOG_PATH"
    [ ! $DEBUG_MODE == 'true' ] && exit 1
  else
    echo -e "${GREEN}[✓] Lines number of environment files matched.${RESET_COLOR}" > "$CHECKING_ERROR_LOG_PATH"
  fi
}

checking_env_variable () {
  error_flag=false
  ENV_VARIABLE=$(cat .env | sed 's;=.*;;')
  . ./.env.example
  for var in $ENV_VARIABLE
  do
    TEST=${!var+::undefined::}
    TEST="${!var=::undefined::}"
    if [ "$TEST" = "::undefined::" ]; then
      echo -e "${RED}[✗] Please define $var variable at .env.example${RESET_COLOR}:" $value  > "$CHECKING_ERROR_LOG_PATH"
      error_flag=true
    fi
  done
  if [ $error_flag != false ]; then
      [ ! $DEBUG_MODE = 'true' ] && exit 1
  else
    echo -e "${GREEN}[✓] Variable consistency between environment files matched.${RESET_COLOR}" > "$CHECKING_ERROR_LOG_PATH"
  fi
}

checking_using_of_env () {
  if [ "$ENV_USING_CHECKING_DIRS" = '' ]; then
      echo -e "${ORANGE}[!] There are no file to check.${RESET_COLOR}" > "$CHECKING_ERROR_LOG_PATH"
      return
  fi
  use_env_directly=$(grep -rn $ENV_USING_CHECKING_DIRS -e "env([[:alnum:] ',_]*)"|grep "[^#]env([[:alnum:] ',_]*)")
  if [ "$use_env_directly" != '' ]; then
    echo -e "${RED}[✗] Failed: these following files are using environment variables directly:${RESET_COLOR}" > "$CHECKING_ERROR_LOG_PATH"
    echo "$use_env_directly\n" > "$CHECKING_ERROR_LOG_PATH"
    [ ! $DEBUG_MODE == 'true' ] && exit 1
  else
    echo -e "${GREEN}[✓] Checking completed, no files using environment variables in wrong way.${RESET_COLOR}\n" > "$CHECKING_ERROR_LOG_PATH"
  fi
}

echo -e "${BLUE}- Checking environment variable:${RESET_COLOR}" > "$CHECKING_ERROR_LOG_PATH"
checking_env_lines
[ $? == 1 ] && exit 1
checking_env_variable
[ $? == 1 ] && exit 1
checking_using_of_env
[ $? == 1 ] && exit 1
