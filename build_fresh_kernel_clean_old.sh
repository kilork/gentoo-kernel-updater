#!/bin/bash
# Gentoo kernel update script
# Copyright (C) 2010  Alexander Korolyoff (kkilork at gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
VERSION='0.01'

KERNEL_PREFIX="/usr/src/linux-"

tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$

function clean_kernel {
	kshort=`echo $1 | sed "s/-gentoo//"`
	emerge -C =gentoo-sources-$kshort
	rm $KERNEL_PREFIX$1 -rf
	rm /boot/{initramfs,System.map,kernel}-genkernel-x86_64-$1
	rm /lib/modules/$1 -rf
	sed "/$1)/,/^$/d" $tempfile -i
}

function clean_kernels {
	cp /boot/grub/grub.conf $tempfile
	for kernel in $choised_kernels; do
		clean_kernel `echo $kernel | sed "s/\"//g"`
	done
	diff /boot/grub/grub.conf $tempfile -u | more
	mv $tempfile /boot/grub/grub.conf -i
}

function find_active_kernel {
	kernels=`eselect kernel list | grep linux | cut -b15- | cut -f1 -d" "`
	b=
	for k in $kernels; do
		b="$b $k $k "
	done
	dialog --menu "Select kernel to build" 0 0 0 $b 2> $tempfile
	retval=$?
	choise=`cat $tempfile`
	case $retval in
		0)
			echo "$choise"
			eselect kernel set linux-$choise;;
		1) exit 1;;
		255) exit 255;;
		*) exit $retval;;
	esac
	active_kernel=`eselect kernel list | grep '*' | cut -b15- | cut -f1 -d" "`
}

function list_kernels {
	kernels=`eselect kernel list | grep linux | cut -b15- | cut -f1 -d" "`
	b=
	for k in $kernels; do
  		b="$b $k $k 1 "  
	done
	echo "$b"

	dialog --checklist "Select kernels to clean" 0 0 0 $b 2> $tempfile

	retval=$?

	choised_kernels=`cat $tempfile`
	case $retval in
    		0)
			echo "$choised_kernels"
			genkernel --oldconfig --save-config all
			clean_kernels;;
    		1) exit 1;;
    		255) exit 255;;
    		*) exit $retval;;
	esac
}

function choose_config {
	kernels=`eselect kernel list | grep linux | cut -b15- | cut -f1 -d" "`
	b=
	for k in $kernels; do
		if [ -e "$KERNEL_PREFIX$k/.config" ]
		then
			b="$b $k $k "
		fi
	done
	dialog --menu "Select kernel .config" 0 0 0 $b 2> $tempfile
	retval=$?
	choise=`cat $tempfile`
	case $retval in
		0)
			echo "$choise";;
		1) exit 1;;
		255) exit 255;;
		*) exit $retval;;
	esac
}

find_active_kernel
if [ ! -e "$KERNEL_PREFIX$active_kernel/.config" ]
then
	choose_config
	cp $KERNEL_PREFIX$choise/.config $KERNEL_PREFIX$active_kernel/
fi
list_kernels
exit
