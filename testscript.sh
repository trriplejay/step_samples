#! /bin/bash


echo "this script is executed in a subshell that inherits ENV from the parent"

add_run_variables "foo=bar" "hello=world"
save_tests features/*
echo "my token is $res_utilRepo_gitProvider_token"