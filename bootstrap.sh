#! /bin/sh

##  bootstrap.sh file for vlc, the VideoLAN Client
##  $Id: bootstrap.sh,v 1.11 2002/08/24 11:57:07 sam Exp $
##
##  Authors: Samuel Hocevar <sam@zoy.org>

###
###  get a sane environment
###
export LANG=C

###
###  argument check
###
do_po=no
while test $# -gt 0; do
  case "$1" in
    --update-po)
      do_po=yes
      ;;
    *)
      echo "unknown option $1"
      ;;
  esac
  shift
done

##
##  autoconf && autoheader
##
echo -n " + running the auto* tools: "
autoconf || exit $?
echo -n "autoconf "
autoheader || exit $?
echo "autoheader."


##
##  headers which need to be regenerated because of the VLC_EXPORT macro
##
file=src/misc/modules_plugin.h
echo -n " + creating headers: "
rm -f $file
sed 's#.*\$[I][d]:.*# * Automatically generated from '$file'.in by bootstrap.sh#' < $file.in > $file
echo '#define STORE_SYMBOLS( p_symbols ) \' >> $file
cat include/*.h | grep '^ *VLC_EXPORT.*;' | \
       sed 's/VLC_EXPORT( *\([^,]*\), *\([^,]*\), *\(.*\));.*/    (p_symbols)->\2_inner = \2; \\/' >> $file
echo '' >> $file
echo -n "$file "

file=include/vlc_symbols.h
rm -f $file && touch $file
echo '/* DO NOT EDIT THIS FILE ! It was generated by bootstrap.sh */' >> $file
echo '' >> $file
echo 'struct module_symbols_t' >> $file
echo '{' >> $file
cat include/*.h | grep '^ *VLC_EXPORT.*;' | \
       sed 's/VLC_EXPORT( *\([^,]*\), *\([^,]*\), *\(.*\));.*/    \1 (* \2_inner) \3;/' | sort >> $file
echo '};' >> $file
echo '' >> $file
echo '#ifdef __PLUGIN__' >> $file
cat include/*.h | grep '^ *VLC_EXPORT.*;' | \
       sed 's/VLC_EXPORT( *\([^,]*\), *\([^,]*\), *\(.*\));.*/#   define \2 p_symbols->\2_inner/' | sort >> $file
echo '#endif /* __PLUGIN__ */' >> $file
echo '' >> $file
echo "$file."


##
##  Glade sometimes sucks
##
echo -n " + fixing glade bugs: "
for file in gnome_interface.c gtk_interface.c
do
if grep "DO NOT EDIT THIS FILE" modules/gui/gtk/$file 2>&1 > /dev/null
then
    rm -f /tmp/$$.$file.bak
    cat > /tmp/$$.$file.bak << EOF
/* This file was created automatically by glade and fixed by bootstrap.sh */

#include <vlc/vlc.h>
EOF
    tail +8 modules/gui/gtk/$file \
        | sed 's#_("-:--:--")#"-:--:--"#' \
        | sed 's#_("---")#"---"#' \
        | sed 's#_("--")#"--"#' \
        | sed 's#_("/dev/dvd")#"/dev/dvd"#' \
        | sed 's#_(\("./."\))#\1#' \
        >> /tmp/$$.$file.bak
    mv -f /tmp/$$.$file.bak modules/gui/gtk/$file
fi
echo -n "$file "
done

file=gtk_support.h
if grep "DO NOT EDIT THIS FILE" modules/gui/gtk/$file 2>&1 > /dev/null
then
    rm -f /tmp/$$.$file.bak
    sed 's/DO NOT EDIT THIS FILE.*/This file was created automatically by glade and fixed by bootstrap.sh/ ; s/#if.*ENABLE_NLS.*/#if defined( ENABLE_NLS ) \&\& defined ( HAVE_GETTEXT )/' < modules/gui/gtk/$file > /tmp/$$.$file.bak
    mv -f /tmp/$$.$file.bak modules/gui/gtk/$file
fi
echo "$file."


##
##  Update the potfiles because no one ever does it
##
if test "$do_po" = "no"
then
  echo "not updating potfiles. use --update-po to force doing it."
else
  echo -n " + updating potfiles: "
  cd po
  make update-po 2>&1 | grep '^[^:]*:$' | cut -f1 -d: | tr '\n' ' ' | sed 's/ $//'
  cd ..
  echo "."
fi

