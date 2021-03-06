DIR=$(dirname "$0")
. "$DIR"/.color
. ./.amv_lint.env

main_lang=en
language_path=./resources/lang/
language_list=`ls ./resources/lang`
checking_language () {
  error_flag=false
  dir=`ls ./resources/lang/$main_lang`

  # Scanning in main language dir...
  for entry in $dir
  do
    MAIN_LANGUAGE_FILE=$language_path$main_lang/$entry
    "$DIR"/utilities.sh count_file_line "$MAIN_LANGUAGE_FILE"
    main_lang_file_line=$?

    for lang in $language_list
    do
      item_checking_error_flag=false
      file_to_compare=$language_path$lang/$entry
      if [ ! -f "$language_path$lang/$entry" ]; then
        echo "${RED}[✗] $entry file is not exist in $lang language${RESET_COLOR}\n" >> "$CHECKING_ERROR_LOG_PATH"
        item_checking_error_flag=true
        error_flag=true
      fi

      "$DIR"/utilities.sh count_file_line "$file_to_compare"
      compare_file_line=$?

      if [ $compare_file_line != $main_lang_file_line ]; then
        echo "${RED}[✗] $entry between $lang and $main_lang languages not same line${RESET_COLOR}\n" >> "$CHECKING_ERROR_LOG_PATH"
        item_checking_error_flag=true
        error_flag=true
      fi
    done

    if [ $item_checking_error_flag = false ]; then
        echo "${GREEN}[✓] $entry${RESET_COLOR} files are matched.\n" >> "$CHECKING_ERROR_LOG_PATH"
    fi
  done

  checking_language_result=$(php -q "$DIR"/check_language_support.php $main_lang)
  if [ "$checking_language_result" != '' ]; then
      echo "${RED}[✗] $checking_language_result${RESET_COLOR}\n" >> "$CHECKING_ERROR_LOG_PATH"
      error_flag=true
  fi

  if [ $error_flag != false ]; then
      [ ! $DEBUG_MODE == 'true' ] && exit 1
  fi
}

echo "${BLUE}- Checking consistency of language translation files:${RESET_COLOR}\n" >> "$CHECKING_ERROR_LOG_PATH"
checking_language
exit $?
