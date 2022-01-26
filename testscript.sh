#! /bin/bash


echo "this script is executed in a subshell that inherits ENV from the parent"

add_run_variables "foo=bar" "hello=world"
write_output settings_bag "date=$(date +%s)" "run_id=$run_id"
echo "my token is $res_utilRepo_gitProvider_token"