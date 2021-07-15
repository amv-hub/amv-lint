. ./.amv_lint.env
PHP_CONVENTION_CHECKING_DIRS=$1
DEBUG_MODE=$2
FIX=$3
checking_php () {
  if [ "$PHP_CONVENTION_CHECKING_DIRS" = '' ]; then
    echo "${ORANGE}[!] There are no files to check.${RESET_COLOR}\n"
      return
  fi

  if [ "$FIX" = '--fix' ]; then
    checking_php_result=$(php vendor/bin/phpcbf --standard=$CHECKING_STANDARDS $PHP_CONVENTION_CHECKING_DIRS)
    php_log_path=$LOGS_FILE_PATH$PHP_ERROR_LOG_FILE_NAME"_"$LOG_DATE$LOGS_FILE_EXTENSION
    echo -e "${GREEN}[✓] Fixing completed. Please check fixed log at: \"$php_log_path\"${RESET_COLOR}\n"
    echo "$checking_php_result" > "$php_log_path"
    exit 0
  else
    checking_php_result=$(php vendor/bin/phpcs --standard=$CHECKING_STANDARDS $PHP_CONVENTION_CHECKING_DIRS -n)
  fi
  if [ "$checking_php_result" != '' ]; then
    php_log_path=$LOGS_FILE_PATH$PHP_ERROR_LOG_FILE_NAME"_"$LOG_DATE$LOGS_FILE_EXTENSION
    echo -e "${RED}[✗] There are some errors: Please checking these errors in your \"$php_log_path\"${RESET_COLOR}\n"
    echo "$checking_php_result" > "$php_log_path"
    [ ! $DEBUG_MODE == 'true' ] && exit 1
  else
    echo "${GREEN}[✓] Passed !!!${RESET_COLOR}\n"
  fi
}

checking_for_development_code() {
  result_a=$(grep -rn PHP_CONVENTION_CHECKING_DIRS -e "dd([[:alnum:] ',_]*)"|grep "[^#]dd([[:alnum:] ',_]*)")
  result_b=$(grep -rn PHP_CONVENTION_CHECKING_DIRS -e "var_dump([[:alnum:] ',_]*)"|grep "[^#]var_dump([[:alnum:] ',_]*)")
  if [ "$result_a" != '' ]; then
    echo -e "${RED}[✗] Failed: these following files have a development code:${RESET_COLOR}"
    echo "$result_a\n"
    [ ! $DEBUG_MODE == 'true' ] && exit 1
  else
    echo -e "${GREEN}[✓] Checking completed, no files using development code.${RESET_COLOR}\n"
  fi

  if [ "$result_b" != '' ]; then
    echo -e "${RED}[✗] Failed: these following files have a development code:${RESET_COLOR}"
    echo "$result_b\n"
    [ ! $DEBUG_MODE == 'true' ] && exit 1
  else
    echo -e "${GREEN}[✓] Checking completed, no files using development code.${RESET_COLOR}\n"
  fi
}

echo "\n${BLUE}- Checking for using development code in PHP files:${RESET_COLOR}"
checking_for_development_code
echo "\n${BLUE}- Checking for coding convention of PHP files:${RESET_COLOR}"
checking_php
exit 0