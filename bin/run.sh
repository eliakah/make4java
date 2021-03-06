#! /bin/sh

# make4java - A Makefile for Java projects
#
# Written in 2015 by Francesco Lattanzio <franz.lattanzio@gmail.com>
#
# To the extent possible under law, the author have dedicated all
# copyright and related and neighboring rights to this software to
# the public domain worldwide. This software is distributed without
# any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication
# along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

cd "$(dirname "$(which "$0")")/.."
java -Djava.class.path=lib/bar-${bar.version}.jar -Djava.library.path=${native.path} dummy.bar.Main
