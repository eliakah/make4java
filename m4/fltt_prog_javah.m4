# make4java - A Makefile for Java projects
#
# Written in 2016 by Francesco Lattanzio <franz.lattanzio@gmail.com>
#
# To the extent possible under law, the author have dedicated all
# copyright and related and neighboring rights to this software to
# the public domain worldwide. This software is distributed without
# any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication
# along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# FLTT_PROG_JAVAH
# ---------------
# Locate the Java C header generator and verify that it is working. We
# cannot just locate it as some OS makes use of wrapper scripts which
# may fail to work under several circumstances.
# It also locate the jni.h header file. It try first looking under the
# "include" subdirectory of the directory specified in the "java.home"
# property (read from javah's "showSettings" output).
# If jni.h is not there and the user specified the JAVA_PREFIX variable,
# then it try looking in the "$JAVA_PREFIX/include" directory.
AC_DEFUN([FLTT_PROG_JAVAH],
         [AC_REQUIRE([AC_CANONICAL_BUILD])[]dnl
AC_REQUIRE([AC_PROG_SED])[]dnl
AC_REQUIRE([FLTT_PROG_JAVAC])[]dnl
AC_ARG_VAR([JAVA_PREFIX], [path to the Java home directory])[]dnl
AC_LANG_COMPILER(C)[]dnl This is a trick to avoid the "Expanded Before
dnl                      Required" warning message.
m4_define([fltt_javah_test],
          [AS_IF([test ! -f Conftest.class],
                 [AS_IF([test "x$JAVAC" = x],
                        [AS_ECHO(["$as_me: javah test failed:"]) >&AS_MESSAGE_LOG_FD
AS_ECHO(["  cannot proceed without a working Java compiler"]) >&AS_MESSAGE_LOG_FD],
                        [cat >Conftest.java <<EOF
public class Conftest {
    public native int somefun(int n);
}
EOF
AS_IF([$JAVAC Conftest.java >/dev/null 2>&1 &&
       test -f Conftest.class], [],
      [AS_ECHO(["$as_me: failed program was:"]) >&AS_MESSAGE_LOG_FD
$SED 's/^/| /' Conftest.java >&AS_MESSAGE_LOG_FD])])])
AS_IF([test -f Conftest.class],
      [AS_IF([$ac_path_JAVAH Conftest >/dev/null 2>&1 &&
              test -f Conftest.h],
             [ac_cv_path_JAVAH=$ac_path_JAVAH ac_path_JAVAH_found=:],
             [AS_ECHO(["$as_me: javah test failed:"]) >&AS_MESSAGE_LOG_FD
$SED 's/^/| /' Conftest.java >&AS_MESSAGE_LOG_FD])])])dnl
AS_IF([test "x$JAVA_PREFIX" = x],
      [AC_CACHE_CHECK([for the Java C header and stub file generator],
                      [ac_cv_path_JAVAH],
                      [AC_PATH_PROGS_FEATURE_CHECK([JAVAH], [javah],
                                                   [fltt_javah_test],
                                                   [ac_cv_path_JAVAH=no])])],
      [AC_CACHE_CHECK([for the Java C header and stub file generator],
                      [ac_cv_path_JAVAH],
                      [AC_PATH_PROGS_FEATURE_CHECK([JAVAH], [javah],
                                                   [fltt_javah_test],
                                                   [ac_cv_path_JAVAH=no],
                                                   [$JAVA_PREFIX/bin])])])
m4_undefine([fltt_javah_test])dnl
rm -f Conftest.java Conftest.class Conftest.h
AS_IF([test "x$ac_cv_path_JAVAH" != xno],
      [JAVAH=$ac_cv_path_JAVAH])
AC_SUBST([JAVAH])[]dnl
AC_ARG_VAR([JAVAH], [Java C header and stub file generator])dnl
dnl Check for jni.h's location
AS_CASE([$build_os],
        [cygwin*|mingw*], [fltt_os=win32],
        [fltt_os=`AS_ECHO($build_os) | $SED 's,@<:@-0-9@:>@.*,,'`])
AC_CACHE_CHECK([for jni.h's location],
               [fltt_cv_path_JNI_H],
               [fltt_cv_path_JNI_H=no
AS_IF([test "x$JAVAH" = x],
      [AS_ECHO(["$as_me: cannot locate jni.h:"]) >&AS_MESSAGE_LOG_FD
AS_ECHO(["  proceeding without a working Java C header generator is pointless"]) >&AS_MESSAGE_LOG_FD],
      [fltt_save_CPPFLAGS=$CPPFLAGS
fltt_javahome=`$JAVAH -J-XshowSettings:properties -help 2>&1 | $SED -n 's|^ *java\.home *= *\(.*\)/@<:@^/@:>@*/\{0,1\}$|\1|p'`
AS_IF([test "x$fltt_javahome" != x && test -d "$fltt_javahome/include"],
      [CPPFLAGS="$fltt_save_CPPFLAGS -I$fltt_javahome/include -I$fltt_javahome/include/$fltt_os"
AC_COMPILE_IFELSE([AC_LANG_SOURCE([@%:@include <jni.h>])],
                  [fltt_cv_path_JNI_H=$fltt_javahome/include],
                  [AS_ECHO(["$as_me: could not find (a working) jni.h, have looked in: $fltt_javahome/include"]) >&AS_MESSAGE_LOG_FD])])
AS_IF([test "x$fltt_cv_path_JNI_H" = xno && test "x$JAVA_PREFIX" != x &&
       test "$fltt_javahome/include" != "$JAVA_PREFIX/include" &&
       test -d "$JAVA_PREFIX/include"],
      [CPPFLAGS="$fltt_save_CPPFLAGS -I$JAVA_PREFIX/include -I$JAVA_PREFIX/include/$fltt_os"
AC_COMPILE_IFELSE([AC_LANG_SOURCE([@%:@include <jni.h>])],
                  [fltt_cv_path_JNI_H=$JAVA_PREFIX/include],
                  [AS_ECHO(["$as_me: could not find (a working) jni.h, have looked in: $JAVA_PREFIX/include"]) >&AS_MESSAGE_LOG_FD])])
CPPFLAGS=$fltt_save_CPPFLAGS])])
AS_IF([test "x$fltt_cv_path_JNI_H" != xno],
      [JAVAH_CPPFLAGS="$JAVAH_CPPFLAGS -I$fltt_cv_path_JNI_H -I$fltt_cv_path_JNI_H/$fltt_os"])
AC_SUBST([JAVAH_CPPFLAGS])[]dnl
AC_ARG_VAR([JAVAH_CPPFLAGS], [CPPFLAGS for native Java source code])dnl
])# FLTT_PROG_JAVAH