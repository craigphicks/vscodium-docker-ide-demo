# args 1:expected, 2:actual, 3:id  
check_exit_status() {
  if [ $2 -ne $1 ]; then
    echo "TEST FAIL: $3 failed: exit code $2 not equal to expected exit code $1"
    return 1
  else 
    echo "TEST PASS: $3 passed"
    return 0 
  fi
}

./build-run-ide.sh
check_exit_status 1 $? "expect error because no args" || exit $?

sleep 1

./build-run-ide.sh secret --no-build
check_exit_status 1 $? "expect error because extra args" || exit $?

sleep 1

./build-run-ide.sh secret
check_exit_status 0 $? "./build-run-ide.sh secret (1st time)"

sleep 1

./build-run-ide.sh secret
check_exit_status 0 $? "./build-run-ide.sh secret (2nd time)"

sleep 1

./build-run-ide.sh --no-build secret
check_exit_status 0 $? "./build-run-ide.sh --no-build secret" || exit $?
