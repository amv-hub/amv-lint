#!/bin/bash

if [ ! -f ./.amv_lint.env ]; then
    echo "${RED}[✗] The initial of package isn't done yet. Please run:${RESET_COLOR}"
    echo "    ./vendor/amv-hub/amv-lint/init-linux.sh\n"
    exit 1;
fi
# Variable define
. ./.amv_lint.env
PARAM2=$2
PARAM3=$3
PARAM4=$4
if [ "$PARAM2" == '-g' ]
then
    DEBUG_MODE=true
elif [ "$PARAM2" == '-c' ]
then
    DEBUG_MODE=false
fi

DIR=./vendor/$PACKAGE_NAME
# Define text color
. "$DIR"/bin/.color

PHP_STAGED_FILES=$(git diff --cached --name-only --diff-filter=AM | grep -e '\.php$')
JS_STAGED_FILES=$(git diff --cached --name-only --diff-filter=AM | grep -e '\.js$')

if [ $DEBUG_MODE == true ]; then
  clear
  rm -rf ./storage/logs/pre_commit_checking/*
fi
echo '' > $CHECKING_ERROR_LOG_PATH
echo "=============================== Ambition Vietnam PHP Linter ===================================="
# Check current executing file and if check staged files
if [ $IS_STAGED_CHECKING == true ] || [ "$PARAM2" == '-c' ]; then
    echo -e "${ORANGE}- We will checking for staged files.${RESET_COLOR}"
    ENV_USING_CHECKING_DIRS=$(git diff --cached --name-only --diff-filter=AM | grep -E '^[^config]' | awk '{print $1}')
    PHP_CONVENTION_CHECKING_DIRS=$PHP_STAGED_FILES
    JS_CONVENTION_CHECKING_DIRS=$JS_STAGED_FILES
fi

lint() {
  BIN_DIR=./vendor/"$PACKAGE_NAME"/bin/
  CHECK_TYPE=$PARAM3
  IS_FIX=$PARAM4
  if [ "$PARAM2" != '-g' ] && [ "$PARAM2" != '-c' ]; then
      CHECK_TYPE=$PARAM2
      IS_FIX=$PARAM3
  fi

  fix_syntax=
  if [ "$IS_FIX" == '--fix' ]; then
      fix_syntax='--fix'
  fi

  case $CHECK_TYPE in
  php)
    sh "$BIN_DIR"check_php.sh "$PHP_CONVENTION_CHECKING_DIRS" $DEBUG_MODE "$fix_syntax"
    [ $? == 1 ] && exit 1
    exit 0
    ;;
  js)
    sh "$BIN_DIR"check_javascript.sh "$JS_CONVENTION_CHECKING_DIRS" $DEBUG_MODE "$fix_syntax"
    [ $? == 1 ] && exit 1
    exit 0
    ;;
  env)
    bash "$BIN_DIR"check_env.sh "$ENV_USING_CHECKING_DIRS" $DEBUG_MODE
    [ $? == 1 ] && exit 1
    exit 0
    ;;
  lang)
    sh "$BIN_DIR"check_language.sh
    [ $? == 1 ] && exit 1
    exit 0
    ;;
  --fix)
    sh "$BIN_DIR"check_php.sh "$PHP_CONVENTION_CHECKING_DIRS" $DEBUG_MODE --fix
    sh "$BIN_DIR"check_javascript.sh "$JS_CONVENTION_CHECKING_DIRS" $DEBUG_MODE --fix
    exit 0
    ;;
  esac

  bash "$BIN_DIR"check_env.sh "$ENV_USING_CHECKING_DIRS" $DEBUG_MODE
  echo_logs
  [ $? == 1 ] && exit 1

  # Checking language translation files
  bash "$BIN_DIR"check_language.sh
  echo_logs
  [ $? == 1 ] && exit 1

  # Create logs dir if not exist
  if [ ! -d $LOGS_FILE_PATH ]; then
    mkdir $LOGS_FILE_PATH
  fi

  # Checking for coding convention, coding styles of PHP
  bash "$BIN_DIR"check_php.sh "$PHP_CONVENTION_CHECKING_DIRS" $DEBUG_MODE
  echo_logs
  [ $? == 1 ] && exit 1

  # Checking for coding convention, coding styles of JavaScript
  bash "$BIN_DIR"check_javascript.sh "$JS_CONVENTION_CHECKING_DIRS" $DEBUG_MODE
  echo_logs
  [ $? == 1 ] && exit 1

  echo -e "${GREEN}=> Ok all checking passed. Congratulations !!${RESET_COLOR}"
  [ $DEBUG_MODE == 'true' ] && exit 1
}

fix () {
  echo "${BLUE}- Begin to fix JavaScript conventions:${RESET_COLOR}"

  checking_js_result=$(npx eslint --fix $JS_CONVENTION_CHECKING_DIRS)
  if [ "$checking_js_result" != '' ]; then
    js_log_path=$LOGS_FILE_PATH$JS_ERROR_LOG_FILE_NAME"_"$LOG_DATE$LOGS_FILE_EXTENSION
    echo "${RED}[✗] There are still some errors: Please check these errors in your \"$js_log_path\"${RESET_COLOR}\n"
    echo "$checking_js_result" > "$js_log_path"
  else
    echo "${GREEN}[✓] Passed !!!${RESET_COLOR}\n"
  fi

  echo "${BLUE}- Begin to fix PHP conventions:${RESET_COLOR}"
  checking_php_result=$(php vendor/bin/phpcbf $PHP_CONVENTION_CHECKING_DIRS)
  if [ "$checking_php_result" != '' ]; then
    php_log_path=$LOGS_FILE_PATH$PHP_ERROR_LOG_FILE_NAME"_"$LOG_DATE$LOGS_FILE_EXTENSION
    echo "${RED}[✗] There are still some errors: Please checking these errors in your \"$php_log_path\"${RESET_COLOR}\n"
    echo "$checking_php_result" > "$php_log_path"
    [ ! $DEBUG_MODE == 'true' ] && exit 1
  else
    echo "${GREEN}[✓] Passed !!!${RESET_COLOR}\n"
  fi
}

hooks() {
  params1=$1
  echo $params1
  exit 1
  if [ $params1 == 'enable' ]; then
      cp "$DIR"/hooks/* ./.git/hooks/pre-commit
  fi
}

clear_logs () {
  rm -rf ./storage/logs/pre_commit_checking/*
}

echo_logs () {
  value=`cat "$CHECKING_ERROR_LOG_PATH"`
  echo -e $value
  echo "" > $CHECKING_ERROR_LOG_PATH
}

"$@"
exit 0
