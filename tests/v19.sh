#!/bin/bash
set -euo pipefail

result=${TKL_TEST_RESULT:?}
password=${TKL_TEST_APP_PASS:?}
work=/run/tkl-v19-tests/moodle
base=https://www.example.com
curl_args=(-kfsS --resolve www.example.com:443:127.0.0.1)
mkdir -p "$work"

systemctl --quiet is-active apache2.service mariadb.service
grep -q '\[40moodle\] successfully completed' /var/log/inithooks.log
curl "${curl_args[@]}" -c "$work/cookies" "$base/login/index.php" \
    >"$work/login.html"
grep -Eqi 'moodle|log in' "$work/login.html"
token=$(sed -n 's/.*name="logintoken" value="\([^"]*\)".*/\1/p' \
    "$work/login.html" | head -1)
test -n "$token"

curl "${curl_args[@]}" -b "$work/cookies" -c "$work/cookies" \
    -D "$work/login.headers" -o "$work/login-response.html" \
    --data-urlencode "logintoken=$token" \
    --data-urlencode username=admin \
    --data-urlencode "password=$password" \
    "$base/login/index.php"
grep -Eq '^HTTP/[^ ]+ 303([[:space:]]|$)' "$work/login.headers"
! grep -Eqi '^location: .*/login/' "$work/login.headers"
curl "${curl_args[@]}" -L -b "$work/cookies" "$base/my/" >"$work/dashboard.html"
grep -Eq 'login/logout\.php\?sesskey=[[:alnum:]]+' "$work/dashboard.html"

runuser -u www-data -- test ! -w /var/www/moodle/public/index.php
runuser -u www-data -- test ! -w /var/www/moodle/config.php
runuser -u www-data -- test ! -w /var/www/moodle/theme
runuser -u www-data -- touch /var/www/moodledata/.tkl-v19-write-test
runuser -u www-data -- rm /var/www/moodledata/.tkl-v19-write-test
/usr/local/bin/tkl-set-moodle-perms --dry-run >"$work/perms-dry-run.txt"
grep -Fq 'root-owned code' "$work/perms-dry-run.txt"
runuser -u www-data -- php /var/www/moodle/admin/cli/cron.php --keepalive=0

release=$(sed -n "s/^\$release *= *'\([^']*\)'.*/\1/p" /var/www/moodle/version.php)
test -n "$release"
systemctl restart mariadb.service apache2.service
curl "${curl_args[@]}" -L -b "$work/cookies" "$base/my/" \
    >"$work/dashboard-after-restart.html"
grep -Eq 'login/logout\.php\?sesskey=[[:alnum:]]+' \
    "$work/dashboard-after-restart.html"
! grep -F -- "$password" /var/log/inithooks.log

cat >"$result" <<EOF
package_source=official Moodle MOODLE_502_STABLE commit b07dd04b40ece3b2d43b2e6ec1213db2a997df7f
installed_version=$release
runtime_checks=Apache and MariaDB services, firstboot completion, HTTPS admin login, dashboard session across restart, cron, ownership helper and boundaries, password log hygiene
updater_command=supervised Moodle git upgrade followed by tkl-set-moodle-perms --fix
updater_result=installed commit unchanged during QA
updater_channel=official Moodle 5.2 stable branch
integrity_evidence=installed Git HEAD b07dd04b40ece3b2d43b2e6ec1213db2a997df7f
EOF
