#!/bin/sh
# Copyright (C) 2007 Jari Aalto; Licenced under GPL v2 or later
#
# /etc/postinstall/<package>.sh -- Custom installation steps

PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/X11R6/bin:$PATH"

set -e

Environment()
{
    #  Define variables to the rest of the script

    [ "$1" ] && dest="$1"        # install destination

    if [ "$dest" ]; then
        #  Delete trailing slash
        dest=$(echo $dest | sed -e 's,/$,,' )
    fi

    package="msmtp"        #!! CHANGE THIS

    #   This file will be installed as
    #   /etc/postinstall/<package>.sh so derive <package>
    #   But if this file is run from CYGIN-PATCHES/postinstall.sh
    #   then we do not know the package name

    name=$(echo $0 | sed -e 's,.*/,,' -e 's,\.sh,,' )

    if [ "$name" != "postinstall" ]; then
        package="$name"
    fi

    bindir="$dest/usr/bin"
    libdir="$dest/usr/lib"
    libdirx11="$dest/usr/lib/X11"
    includedir="$dest/usr/include"

    sharedir="$dest/usr/share"
    infodir="$sharedir/info"
    docdir="$sharedir/doc"
    etcdir="$dest/etc"

    #   1) list of files to be copied to /etc
    #   2) Source locations

    conffiles_to="$etcdir/preremove/$package-manifest.lst"
    conffiles_from="$etcdir/preremove/$package-manifest-from.lst"
}

Warn ()
{
    echo "$@" >&2
}

Run ()
{
    ${test+echo} "$@"
}

InstallConffiles ()
{
    [ ! -f $conffiles_to ] && return

    #  Install default configuration files for system wide

    latest=$(LC_ALL=C find /usr/share/doc/$package*/ \
               -maxdepth 0 -type d \
             | sort | tail -1 | sed 's,/$,,')

    if [ ! "$latest" ]; then
        Warn "$0: [FATAL] Cannot find $package install doc dir"
        exit 1
    fi

    [ ! -f $conffiles_from ] && return
    [ ! -f $conffiles_to   ] && return

    tmpprefix=${TEMPDIR:-/tmp}/tmp$$
    from=$tmpprefix.from
    to=$tmpprefix.to

    #  Filter out all comments. Grep only lines with filenames

    grep -E '^[^#]*/|^[[:space]]*$' $conffiles_from > $from
    grep -E '^[^#]*/|^[[:space]]*$' $conffiles_to   > $to

    paste $from $to  |
    {
        while read from to
        do
            from=$(echo $dest$from | sed "s,\$PKGDOCDIR,$pkgdocdir$latest," )
            to=$(echo $dest$to | sed "s,\$PKG,$pkgdocdir," )

            #  Install only if not already there
            [ ! -f $to ] && Run install -m 0644 $from $to
        done
    }

    rm -f $tmpprefix.*
}

InstalInfo()
{
    cd $infodir || return $?

    central=$infodir/dir

    for file in $infodir/$package*.info
    do
        [ ! -f "$file" ] && continue      # no info files

        Run install-info --dir-file="$central" $file
    done
}

Symlink ()
{
    #  Draw sendmail symlink if not exists

    if [ ! -e /usr/sbin/sendmail ] &&
       [ -x /usr/sbin/msmtp ]
    then
        (cd /usr/sbin && cd ln -s -v msmtp sendmail)
    fi
}

Main()
{
    Environment "$@"    &&
    Symlink             &&
    InstalInfo
}

Main "$@"

# End of file
