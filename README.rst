Moodle - Course Management System
=================================

`Moodle`_ is a popular e-learning software platform, also known as a
Course Management System, with tens of millions of users around the
globe. Moodle is designed to help educators create online courses with
opportunities for rich interaction. Moodle is modular in construction
and can readily be extended by creating plugins for specific new
functionality.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Moodle configurations:
   
   - Installed from upstream source code at /var/www/moodle.
   - SSL logins are forced (security).
   - Includes support for authentication via ldap (convenience).
   - Configured default email address for admin, guest and noreply email
     (@example.com).
   - Set default theme to formal\_white (more attractive).

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Moodle documentation:

- `Teacher documentation`_
- `Administrator documentation`_
- `Developer documentation`_

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Adminer: username: **adminer**
-  Webmin, Webshell, SSH, MySQL: username **root**
-  Moodle: username **admin**


.. _Moodle: http://moodle.org
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Adminer: http://www.adminer.org/
.. _Teacher documentation: http://docs.moodle.org/en/Teacher_documentation
.. _Administrator documentation: http://docs.moodle.org/en/Administrator_documentation
.. _Developer documentation: http://docs.moodle.org/en/Developer_documentation
