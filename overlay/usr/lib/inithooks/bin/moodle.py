#!/usr/bin/python
"""Set Moodle admin password

Option:
    --pass=    unless provided, will ask interactively

"""

import re
import sys
import getopt
import hashlib

from dialog_wrapper import Dialog
from mysqlconf import MySQL

def usage(s=None):
    if s:
        print >> sys.stderr, "Error:", s
    print >> sys.stderr, "Syntax: %s [options]" % sys.argv[0]
    print >> sys.stderr, __doc__
    sys.exit(1)

def _get_passwordsalt(conffile="/var/www/moodle/config.php"):
    for line in file(conffile).readlines():
        line = line.strip()
        m = re.match("\$CFG->passwordsaltmain = '(.*)';", line)
        if m:
            return m.group(1)

    return ""
            
def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ['help', 'pass='])
    except getopt.GetoptError, e:
        usage(e)

    password = ""
    for opt, val in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt == '--pass':
            password = val

    if not password:
        d = Dialog('TurnKey Linux - First boot configuration')
        password = d.get_password(
            "Moodle Password",
            "Enter new password for the Moodle 'admin' account.")

    salt = _get_passwordsalt()
    hashpass = hashlib.md5(password + salt).hexdigest()

    m = MySQL()
    m.execute('UPDATE moodle.user SET password=\"%s\" WHERE username=\"admin\";' % hashpass)

if __name__ == "__main__":
    main()

