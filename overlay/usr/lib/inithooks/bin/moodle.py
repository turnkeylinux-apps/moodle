#!/usr/bin/python3
"""Set Moodle admin password

Option:
    --pass=    unless provided, will ask interactively

"""

import re
import sys
import getopt
import random
import string
import hashlib

from libinithooks.dialog_wrapper import Dialog
from mysqlconf import MySQL


def usage(s=None):
    if s:
        print("Error:", s, file=sys.stderr)
    print("Syntax: %s [options]" % sys.argv[0], file=sys.stderr)
    print(__doc__, file=sys.stderr)
    sys.exit(1)


def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ['help', 'pass='])
    except getopt.GetoptError as e:
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

    salt_chars = string.ascii_letters + string.digits
    salt = "".join(random.choice(salt_chars) for c in range(32))
    hashpass = "%s:%s" % (hashlib.sha256((password + salt).encode('utf8')).hexdigest(), salt)

    m = MySQL()
    m.execute('UPDATE moodle.user SET password=%s WHERE username=\"admin\";',
              (hashpass,))


if __name__ == "__main__":
    main()
