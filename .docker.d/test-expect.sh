#!/usr/bin/expect -f
set timeout 10
set env(TERM) "dumb"

spawn ssh vscodium-docker-ide-demo

expect_before {
    -re "root@.*:~# " {
        # Continue with the script
    }
}

expect -re "root@.*:~# "
send "env | grep TEST_ENV_VAR\r"

expect {
    -re ".*TEST_ENV_VAR=test-env-value.*" {
        send_user "Found TEST_ENV_VAR\n"
        set found 1
    }
    timeout {
        send_user "Timeout waiting for TEST_ENV_VAR\n"
        exit 1
    }
}

expect -re "root@.*:~# "
send "exit\r"
expect eof

if {[info exists found]} {
    exit 0
} else {
    exit 1
}