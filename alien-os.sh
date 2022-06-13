#!/data/data/com.termux/files/usr/bin/bash

# Creation date: 17/11/2021
# Create by: Yovany-Black-Hat

# Colors
black="\e[0;30m"
darkGray="\e[1;30m"
red="\e[0;31m"
lightRed="\e[1;31m"
green="\e[0;32m"
lightGreen="\e[1;32m"
coffee="\e[0;33m"
yellow="\e[1;33m"
blue="\e[0;34m"
blueTwo="\e[1;34m"
purple="\e[0;35m"
lightPurple="\e[1;35m"
lightBlue="\e[0;36m"
lightBlueTwo="\e[1;36m"
gray="\e[0;37m"
white="\e[1;37m"
endColour="\033[0m\e[0m"


# Global variables.
path="/data/data/com.termux/files/home/Alien-OS"
distro_name=""
msg="${lightGreen}[${lightRed}*${lightGreen}]${endColour}"
msg2="${lightGreen}[${lightRed}x${lightGreen}]${endColour}"

function msg-num() {
echo -e "${lightGreen}[${lightRed}$1${lightGreen}] $2${endColour}"
}

function msg3() {
	echo -e "${lightGreen}[${lightRed}$1${lightGreen}]${darkGray} $2${endColour}"
}

trap ctrl_c INT
# Exit function.
function ctrl_c(){
	echo -e "\n\n${msg2}${lightGreen} Saliendo...${endColour}"
	exit 0
}


# Banner printing function.
function banner() {
	source "${path}/Alien/banners/banner.sh"
}


function for_all() {
	local title=$1

	# Comprobamos si existen distros instaladas.
	if [ ! "$(ls ${path}/rootfs 2> /dev/null)" ]; then
		echo -e "\n\n${msg2}${lightRed} Error: No hay ninguna distribución instalada.${endColour}"
		exit 1
	fi

	echo -e $title
	sleep 0.5


	echo -e "${msg}${lightGreen} Listando distribuciones instaladas...${endColour}"
	sleep 0.5


	for i in $(ls "${path}/rootfs"); do
		echo -e "${msg}${lightGreen} Nombre${lightRed}:${green} $i${endColour}"
		sleep 0.5
	done


	echo -e -n "\n${msg}${lightGreen} Ingrese el nombre de su distribucion${lightRed}:${green} "
	read login_distro

}


# Function principal.
function command_install(){
	local rootfs_name="debian-aarch64-pd-v2.2.0.tar.xz"


	banner
	echo -e "\n\n${msg}${lightBlueTwo} Instalar Debian 11 (bullseye)...${endColour}"


	echo -e -n "${msg}${lightGreen} Ingrese un nombre para la distribución${lightRed}:${green} "
	read distro_name
	check_distro_name $distro_name


	echo -e "${msg}${lightGreen} Creando directorio ${path}/rootfs/$distro_name...${endColour}"
	mkdir -m 755 -p "${path}/rootfs/$distro_name"
	sleep 0.5


	# We need this to disable the preloaded libtermux-exec.so library
	# which redefines the 'execve ()' implementation.
	unset LD_PRELOAD


	echo -e "${msg}${lightGreen} Extrayendo rootfs, por favor espere...${endColour}"
	proot --link2symlink \
		tar -C "${path}/rootfs/$distro_name" --warning=no-unknown-keyword \
		--delay-directory-restore --preserve-permissions --strip=1 \
		-xf "${path}/${rootfs_name}" --exclude='dev'||:


	# Write important environment variables in the profile file as /bin/login does not
	# Preserve them.
	local profile_script="${path}/rootfs/$distro_name/etc/profile.d/alien.sh"

	echo -e "${msg}${lightGreen} Escribiendo ${profile_script}...${endColour}"

	cat <<- EOF >> "$profile_script"
	export ANDROID_ART_ROOT=${ANDROID_ART_ROOT-}
	export ANDROID_DATA=${ANDROID_DATA-}
	export ANDROID_I18N_ROOT=${ANDROID_I18N_ROOT-}
	export ANDROID_ROOT=${ANDROID_ROOT-}
	export ANDROID_RUNTIME_ROOT=${ANDROID_RUNTIME_ROOT-}
	export ANDROID_TZDATA_ROOT=${ANDROID_TZDATA_ROOT-}
	export BOOTCLASSPATH=${BOOTCLASSPATH-}
	export COLORTERM=${COLORTERM-}
	export DEX2OATBOOTCLASSPATH=${DEX2OATBOOTCLASSPATH-}
	export EXTERNAL_STORAGE=${EXTERNAL_STORAGE-}
	[ -z "\$LANG" ] && export LANG=C.UTF-8
	export PATH=\${PATH}:/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin
	export TERM=${TERM-xterm-256color}
	export TMPDIR=/tmp
	export PULSE_SERVER=127.0.0.1
	export MOZ_FAKE_NO_SANDBOX=1
	EOF
	sleep 0.5


	# /etc/resolv.conf Puede que no esté configurada.
	echo -e "${msg}${lightGreen} Escribiendo el archivo resolv.conf (NS 1.1.1.1/1.0.0.1)...${endColour}"
	rm -f "${path}/rootfs/$distro_name/etc/resolv.conf"
	cat <<- EOF > "${path}/rootfs/$distro_name/etc/resolv.conf"
	nameserver 1.1.1.1
	nameserver 1.0.0.1
	EOF
	sleep 0.5


	# /etc/hosts Puede estar vacía por defecto en algunas distribuciones.
	echo -e "${msg}${lightGreen} Escribiendo el archivo hosts...${endColour}"
	chmod u+rw "${path}/rootfs/$distro_name/etc/hosts" >/dev/null 2>&1 || true
	cat <<- EOF > "${path}/rootfs/$distro_name/etc/hosts"
	# IPv4.
	127.0.0.1   localhost.localdomain localhost

	# IPv6.
	::1         localhost.localdomain localhost ip6-localhost ip6-loopback
	fe00::0     ip6-localnet
	ff00::0     ip6-mcastprefix
	ff02::1     ip6-allnodes
	ff02::2     ip6-allrouters
	ff02::3     ip6-allhosts
	EOF
	sleep 0.5


	# Add Android specific UID/GID to /etc/group and /etc/gshadow.
	echo -e "${msg}${lightGreen} Registro de UID y GID específicos de Android ...${endColour}"
	chmod u+rw "${path}/rootfs/$distro_name/etc/passwd" \
		"${path}/rootfs/$distro_name/etc/shadow" \
		"${path}/rootfs/$distro_name/etc/group" \
		"${path}/rootfs/$distro_name/etc/gshadow" >/dev/null 2>&1 || true

	echo "aid_$(id -un):x:$(id -u):$(id -g):Android user:/:/sbin/nologin" >> \
		"${path}/rootfs/$distro_name/etc/passwd"

	echo "aid_$(id -un):*:18446:0:99999:7:::" >> \
		"${path}/rootfs/$distro_name/etc/shadow"

	local group_name group_id
	while read -r group_name group_id; do
		echo "aid_${group_name}:x:${group_id}:root,aid_$(id -un)" >> \
			"${path}/rootfs/$distro_name/etc/group"
		if [ -f "${path}/rootfs/$distro_name/etc/gshadow" ]; then
			echo "aid_${group_name}:*::root,aid_$(id -un)" >> \
				"${path}/rootfs/$distro_name/etc/gshadow"
		fi
	done < <(paste <(id -Gn | tr ' ' '\n') <(id -G | tr ' ' '\n'))
	sleep 0.5


	# Make sure proot can bind bogus entries /proc.
	setup_fake_proc


	# Run the distribution-specific optional hook.
	echo -e "${msg}${lightGreen} Ejecutando pasos de configuración específicos de la distribución ...${endColour}"
	cd "${path}/rootfs/$distro_name"
	distro_setup > stdout && rm stdout
	sleep 0.5


	# Calling the settings function
	settings


	# Almacena el nombre de la distibución en la rootfs
	mkdir -p "${path}/rootfs/$distro_name/etc/details-distro"
	echo "$distro_name" > "${path}/rootfs/${distro_name}/etc/details-distro/distro_name.txt"


	# Crea directorio para el usuario de la distro
	echo -e "${msg}${lightGreen} Creando directorio para el usuario > Alien/users/distro-${distro_name}...${endColour}"
	mkdir -p "${path}/Alien/users/distro-${distro_name}"
	sleep 0.5

	echo -e "\n${msg}${lightGreen} Inicie debian con la opcion 2 del menu para configurar debian.${endColour}"
}


function check_distro_name() {
	mkdir -p "${path}/rootfs"
	if [ -f $path/rootfs/$1/etc/profile.d/alien.sh ]; then
		echo -e "\n${msg2}${lightRed} El nombre $1 ya esta en uso.${endColour}"
		exit 1
	fi

}


distro_setup() {
	# Don't update gvfs-daemons and udisks2
	run_proot_cmd apt-mark hold gvfs-daemons udisks2
}


# Special function to execute a command in rootfs.
# Can only be used inside distro_setup ().
run_proot_cmd() {
	local qemu_arg=""
	proot \
		$qemu_arg -L \
		--kernel-release=5.4.0-faked \
		--link2symlink \
		--kill-on-exit \
		--rootfs="${path}/rootfs/$distro_name" \
		--root-id \
		--cwd=/root \
		--bind=/dev \
		--bind="/dev/urandom:/dev/random" \
		--bind=/proc \
		--bind="/proc/self/fd:/dev/fd" \
		--bind="/proc/self/fd/0:/dev/stdin" \
		--bind="/proc/self/fd/1:/dev/stdout" \
		--bind="/proc/self/fd/2:/dev/stderr" \
		--bind=/sys \
		--bind="${path}/rootfs/$distro_name/proc/.loadavg:/proc/loadavg" \
		--bind="${path}/rootfs/$distro_name/proc/.stat:/proc/stat" \
		--bind="${path}/rootfs/$distro_name/proc/.uptime:/proc/uptime" \
		--bind="${path}/rootfs/$distro_name/proc/.version:/proc/version" \
		--bind="${path}/rootfs/$distro_name/proc/.vmstat:/proc/vmstat" \
		/usr/bin/env -i \
			"HOME=/root" \
			"LANG=C.UTF-8" \
			"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
			"TERM=$TERM" \
			"TMPDIR=/tmp" \
			"$@"

}


# A function to prepare fake content for certain /proc
# entries that are known to be restricted on Android.
setup_fake_proc() {
	mkdir -p "${path}/rootfs/$distro_name/proc"
	chmod 700 "${path}/rootfs/$distro_name/proc"

	if [ ! -f "${path}/rootfs/$distro_name/proc/.loadavg" ]; then
		cat <<- EOF > "${path}/rootfs/$distro_name/proc/.loadavg"
		0.54 0.41 0.30 1/931 370386
		EOF
	fi

	if [ ! -f "${path}/rootfs/$distro_name/proc/.stat" ]; then
		cat <<- EOF > "${path}/rootfs/$distro_name/proc/.stat"
		cpu  1050008 127632 898432 43828767 37203 63 99244 0 0 0
		cpu0 212383 20476 204704 8389202 7253 42 12597 0 0 0
		cpu1 224452 24947 215570 8372502 8135 4 42768 0 0 0
		cpu2 222993 17440 200925 8424262 8069 9 17732 0 0 0
		cpu3 186835 8775 195974 8486330 5746 3 8360 0 0 0
		cpu4 107075 32886 48854 8688521 3995 4 5758 0 0 0
		cpu5 90733 20914 27798 1429573 2984 1 11419 0 0 0
		intr 53261351 0 686 1 0 0 1 12 31 1 20 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7818 0 0 0 0 0 0 0 0 255 33 1912 33 0 0 0 0 0 0 3449534 2315885 2150546 2399277 696281 339300 22642 19371 0 0 0 0 0 0 0 0 0 0 0 2199 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2445 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 162240 14293 2858 0 151709 151592 0 0 0 284534 0 0 0 0 0 0 0 0 0 0 0 0 0 0 185353 0 0 938962 0 0 0 0 736100 0 0 1 1209 27960 0 0 0 0 0 0 0 0 303 115968 452839 2 0 0 0 0 0 0 0 0 0 0 0 0 0 160361 8835 86413 1292 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3592 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6091 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 35667 0 0 156823 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 138 2667417 0 41 4008 952 16633 533480 0 0 0 0 0 0 262506 0 0 0 0 0 0 126 0 0 1558488 0 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 8 0 0 6 0 0 0 10 3 4 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 20 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 12 1 1 83806 0 1 1 0 1 0 1 1 319686 2 8 0 0 0 0 0 0 0 0 0 244534 0 1 10 9 0 10 112 107 40 221 0 0 0 144
		ctxt 90182396
		btime 1595203295
		processes 270853
		procs_running 2
		procs_blocked 0
		softirq 25293348 2883 7658936 40779 539155 497187 2864 1908702 7229194 279723 7133925
		EOF
	fi

	if [ ! -f "${path}/rootfs/$distro_name/proc/.uptime" ]; then
		cat <<- EOF > "${path}/rootfs/$distro_name/proc/.uptime"
		284684.56 513853.46
		EOF
	fi

	if [ ! -f "${path}/rootfs/$distro_name/proc/.version" ]; then
		cat <<- EOF > "${path}/rootfs/$distro_name/proc/.version"
		Linux version 5.4.0-faked (termux@androidos) (gcc version 4.9.x (Faked /proc/version by Proot-Distro) ) #1 SMP PREEMPT Fri Jul 10 00:00:00 UTC 2020
		EOF
	fi

	if [ ! -f "${path}/rootfs/$distro_name/proc/.vmstat" ]; then
		cat <<- EOF > "${path}/rootfs/$distro_name/proc/.vmstat"
		nr_free_pages 146031
		nr_zone_inactive_anon 196744
		nr_zone_active_anon 301503
		nr_zone_inactive_file 2457066
		nr_zone_active_file 729742
		nr_zone_unevictable 164
		nr_zone_write_pending 8
		nr_mlock 34
		nr_page_table_pages 6925
		nr_kernel_stack 13216
		nr_bounce 0
		nr_zspages 0
		nr_free_cma 0
		numa_hit 672391199
		numa_miss 0
		numa_foreign 0
		numa_interleave 62816
		numa_local 672391199
		numa_other 0
		nr_inactive_anon 196744
		nr_active_anon 301503
		nr_inactive_file 2457066
		nr_active_file 729742
		nr_unevictable 164
		nr_slab_reclaimable 132891
		nr_slab_unreclaimable 38582
		nr_isolated_anon 0
		nr_isolated_file 0
		workingset_nodes 25623
		workingset_refault 46689297
		workingset_activate 4043141
		workingset_restore 413848
		workingset_nodereclaim 35082
		nr_anon_pages 599893
		nr_mapped 136339
		nr_file_pages 3086333
		nr_dirty 8
		nr_writeback 0
		nr_writeback_temp 0
		nr_shmem 13743
		nr_shmem_hugepages 0
		nr_shmem_pmdmapped 0
		nr_file_hugepages 0
		nr_file_pmdmapped 0
		nr_anon_transparent_hugepages 57
		nr_unstable 0
		nr_vmscan_write 57250
		nr_vmscan_immediate_reclaim 2673
		nr_dirtied 79585373
		nr_written 72662315
		nr_kernel_misc_reclaimable 0
		nr_dirty_threshold 657954
		nr_dirty_background_threshold 328575
		pgpgin 372097889
		pgpgout 296950969
		pswpin 14675
		pswpout 59294
		pgalloc_dma 4
		pgalloc_dma32 101793210
		pgalloc_normal 614157703
		pgalloc_movable 0
		allocstall_dma 0
		allocstall_dma32 0
		allocstall_normal 184
		allocstall_movable 239
		pgskip_dma 0
		pgskip_dma32 0
		pgskip_normal 0
		pgskip_movable 0
		pgfree 716918803
		pgactivate 68768195
		pgdeactivate 7278211
		pglazyfree 1398441
		pgfault 491284262
		pgmajfault 86567
		pglazyfreed 1000581
		pgrefill 7551461
		pgsteal_kswapd 130545619
		pgsteal_direct 205772
		pgscan_kswapd 131219641
		pgscan_direct 207173
		pgscan_direct_throttle 0
		zone_reclaim_failed 0
		pginodesteal 8055
		slabs_scanned 9977903
		kswapd_inodesteal 13337022
		kswapd_low_wmark_hit_quickly 33796
		kswapd_high_wmark_hit_quickly 3948
		pageoutrun 43580
		pgrotated 200299
		drop_pagecache 0
		drop_slab 0
		oom_kill 0
		numa_pte_updates 0
		numa_huge_pte_updates 0
		numa_hint_faults 0
		numa_hint_faults_local 0
		numa_pages_migrated 0
		pgmigrate_success 768502
		pgmigrate_fail 1670
		compact_migrate_scanned 1288646
		compact_free_scanned 44388226
		compact_isolated 1575815
		compact_stall 863
		compact_fail 392
		compact_success 471
		compact_daemon_wake 975
		compact_daemon_migrate_scanned 613634
		compact_daemon_free_scanned 26884944
		htlb_buddy_alloc_success 0
		htlb_buddy_alloc_fail 0
		unevictable_pgs_culled 258910
		unevictable_pgs_scanned 3690
		unevictable_pgs_rescued 200643
		unevictable_pgs_mlocked 199204
		unevictable_pgs_munlocked 199164
		unevictable_pgs_cleared 6
		unevictable_pgs_stranded 6
		thp_fault_alloc 10655
		thp_fault_fallback 130
		thp_collapse_alloc 655
		thp_collapse_alloc_failed 50
		thp_file_alloc 0
		thp_file_mapped 0
		thp_split_page 612
		thp_split_page_failed 0
		thp_deferred_split_page 11238
		thp_split_pmd 632
		thp_split_pud 0
		thp_zero_page_alloc 2
		thp_zero_page_alloc_failed 0
		thp_swpout 4
		thp_swpout_fallback 0
		balloon_inflate 0
		balloon_deflate 0
		balloon_migrate 0
		swap_ra 9661
		swap_ra_hit 7872
		EOF
	fi

}


# Function to start proot.
function command_login() {
	local login_distro
	local user
	local count=0
	banner


	if [ ! "$(ls ${path}/rootfs 2> /dev/null)" ]; then
		echo -e "\n\n${msg2}${lightRed} Error: No hay ninguna distribución instalada.${endColour}"
		exit 1
	fi


	echo -e "\n\n${msg}${lightBlueTwo} Iniciar Debian 11 (bullseye)${endColour}"


	echo -e "\n${msg}${lightGreen} Listando distribuciones instaladas...${endColour}"
	sleep 0.5


	for i in $(ls "${path}/rootfs"); do
		echo -e "${msg}${lightGreen} Nombre${lightRed}:${green} $i${endColour}"
		sleep 0.5
	done


	echo -e -n "\n${msg}${lightGreen} Ingrese el nombre de su distribucion${LightRed}:${green} "
	read login_distro


	for x in $(ls "${path}/rootfs"); do
		if [ "$login_distro" = "$x" ]; then
			count=+1
		fi
	done



	if [ $count -eq 1 ]; then
		echo -e "\n\n${msg}${lightGreen} Iniciando distribución ${login_distro}...${endColour}"

		unset LD_PRELOAD
		command="proot"
		command+=" --link2symlink"
		command+=" -0"
		command+=" -r ${path}/rootfs/$login_distro"

		command+=" -b /dev"
		command+=" -b /proc"
		command+=" -b /data"
		command+=" -b /system"
		command+=" -b /vendor"

		command+=" -b /sdcard:/sdcard"
		command+=" -b $HOME:/termux"
		command+=" -b ${path}/Alien:/Alien"

		command+=" -b ${path}/rootfs/$login_distro/root:/dev/shm"

		command+=" -w /root"
		command+=" /usr/bin/env -i"
		command+=" HOME=/root"

		command+=" ANDROID_DATA=/data"
		command+=" ANDROID_ROOT=/system"

		command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
		command+=" TERM=$TERM"
		command+=" LANG=C.UTF-8"


		user=`cat "${path}/Alien/users/distro-${login_distro}/username.txt" 2>/dev/null`
		if [ -z $user ]; then
			command+=" /bin/su -l root"
			exec $command
		else
			command+=" /bin/su -l ${user}"
			exec $command
		fi

	else
		echo -e "\n\n${msg2}${lightRed} Error: No existe ninguna distribución llamada ${green}'$login_distro'${endColour}"
	fi

}


# Function that removes and installs debian.
function command_delete() {
	local option_remove
	local yes_no

	banner


	echo -e "\n\n${msg}${lightGreen} ¿Qué desea hacer?${endColour}\n"
	msg-num "1" "Eliminar una distribución"
	msg-num "2" "Eliminar una copia (backup)"

	echo -e -n "\n${lightGreen}[${lightRed}~${lightGreen}]${darkGray} Seleccione una opción${lightRed}:${green} "
	read option_remove


	if [ $option_remove = "1" ]; then
		banner
		for_all "\n\n${msg}${lightBlueTwo} Borrar una distribución${endColour}"

		if [ -d "${path}/rootfs/$login_distro" ]; then

			echo -e "\n${msg2}${lightRed} Advertencia: está seguro que desea eliminar la distro '${login_distro}'?${endColour}"
			echo -e -n "\t ${lightGreen}¿Quieres continuar? [Y/n] ${green}"
			read yes_no

			if [ "$yes_no" == "Y" -o "$yes_no" == "y" ]; then
				echo -e "\n\n${msg2}${lightRed} Elimiando directorio $login_distro...${endColour}"
				if rm -rf "$path/rootfs/$login_distro" > /dev/null 2>&1; then
					# Elimina usuario.
					rm -rf "${path}/Alien/users/distro-${login_distro}" > /dev/null 2>&1
					echo -e "${msg}${lightGreen} Eliminado correctamente.${endColour}"
				else
					echo -e "\n${msg2}${lightRed} Error: Hubieron errores al eliminar el directorio $login_distro${endColour}"
				fi

			elif [ "$yes_no" == "N" -o "$yes_no" == "n" ]; then
				echo -e "\n\n${msg2}${lightRed} Cancelado.${endColour}"
				echo -e "${msg2}${lightGreen} Saliendo...${endColour}"
				exit 1

			else
				echo -e "\n${msg2}${lightRed} Opción invalida.${endColour}"
			fi
		else
			echo -e "\n\n${msg2}${lightRed} Error: No existe ninguna distribución llamada ${green}'$login_distro'${endColour}"
		fi


	elif [ $option_remove = "2" ]; then
		banner
		local count=1
		local vari=0
		local name_backup_remove

		echo -e "\n\n${msg}${lightBlueTwo} Borrar una copia (backup)${endColour}"
		sleep 0.5

		function msg4() {
			echo -e "${lightGreen}[${lightRed}$1${lightGreen}] nombre${lightRed}:${green} $2${endColour}"
		}

		# Comprobamos si hay copias creadas.
		if [ ! "$(ls ${path}/backup/alias 2> /dev/null)" ]; then
			echo -e "\n\n${msg2}${lightRed} Error: No hay copias creadas.${endColour}"
			exit 1
		fi

		echo -e "${msg}${lightGreen} Listando los backups creados${endColour}"
		sleep 0.5

		for i in  $(ls ${path}/backup/alias); do
			local var=$(echo $i | tr -d '.txt')

			msg4 "$count" "$var"
			((count++))
			sleep 0.5
		done


		echo -e -n "\n${msg}${lightGreen} Ingrese el nombre de su copia${lightRed}:${green} "
		read name_backup_remove

		for x in  $(ls ${path}/backup/alias); do
			local var=$(echo $x | tr -d '.txt')
			if [ $name_backup_remove = $var ]; then
				vari+=1
			fi
		done

		if [ $vari -eq 1 ]; then
			echo -e "\n${msg2}${lightRed} Advertencia: está seguro que desea eliminar la copia llamada '${name_backup_remove}'?${endColour}"
			echo -e -n "\t ${lightGreen}¿Quieres continuar? [Y/n] ${green}"
			read yes_no

			if [ "$yes_no" == "Y" -o "$yes_no" == "y" ]; then
				echo -e "\n\n${msg}${lightGreen} Eliminando la copia ${name_backup_remove}...${endColour}"
				if rm "$path/backup/alias/${name_backup_remove}.txt" > /dev/null 2>&1; then
					rm "$path/backup/${name_backup_remove}.tar.xz" > /dev/null 2>&1
					echo "${msg}${lightGreen} Se elimino la copia correctamente.${endColour}"
				else
					echo -e "\n${msg2}${lightRed} Error: Hubieron errores al eliminar la copia $name_backup_remove{endColour}"
				fi

			elif [ "$yes_no" == "N" -o "$yes_no" == "n" ]; then
				echo -e "\n\n${msg2}${lightRed} Cancelado.${endColour}"
				echo -e "${msg2}${lightGreen} Saliendo...${endColour}"
				exit 1

			else
				echo -e "\n${msg2}${lightRed} Opción invalida.${endColour}"
			fi

		else
			echo -e "\n\n${msg}${lightRed} Error: No existe ninguna copia (backup) con el nombre de '${name_backup_remove}'${endColour}"
		fi


	else
		echo -e "\n${msg2}${lightRed} Opción invalida.${endColour}"
	fi
}


# Function you write to profile.d for when you start
# configure everything in debian.
function settings() {
	if [ -d "${path}/rootfs/$distro_name" ]; then
		echo -e "${msg}${lightGreen} Escribiendo en $distro_name/etc/profile.d/install-alien.sh...${endColour}"
		cat <<- EOF > "${path}/rootfs/$distro_name/etc/profile.d/alien-install.sh"
		#!/bin/bash

		bash /Alien/alien-os.sh

		EOF

		chmod +x ${path}/rootfs/$distro_name/etc/profile.d/alien-install.sh
		sleep 0.5

	else
		echo -e "${msg2}${lightRed} No existe el directorio debian.${endColour}"
	fi
}


function command_backup() {
	local backup_name
	local ruta
	banner


	# Comprobamos si existen distros instaladas.
	if [ ! "$(ls ${path}/rootfs 2> /dev/null)" ]; then
		echo -e "\n\n${msg2}${lightRed} Error: No hay ninguna distribución instalada para crear la copia.${endColour}"
		exit 1
	fi


	echo -e "\n\n${msg}${lightBlueTwo} Crear copia de seguridad${endColour}"
	sleep 0.5

	echo -e "${msg}${lightGreen} Listando distribuciones instaladas...${endColour}"
	sleep 0.5

	for i in $(ls "${path}/rootfs"); do
		echo -e "${msg}${lightGreen} Nombre${lightRed}:${green} $i${endColour}"
		sleep 0.5
	done


	while true; do
		clear
		banner
		echo -e "\n\n${msg}${lightBlueTwo} Crear copia de seguridad${endColour}"
		echo -e "${msg}${lightGreen} Listando distribuciones instaladas...${endColour}"
		for i in $(ls "${path}/rootfs"); do
			echo -e "${msg}${lightGreen} Nombre${lightRed}:${green} $i${endColour}"
		done

		echo -e "\n${msg}${lightGreen} ¿Qué distribución desea hacer la copia?${endColour}"
		echo -e -n "${msg}${lightGreen} Escriba el nombre${lightRed}:${green} "
		read backup_name
		echo -e "${endColour}"


		if [ -d "${path}/rootfs/${backup_name}" ]; then
			ruta="rootfs/${backup_name}"
			break
		else
			echo -e "${msg2}${lightRed} No existe una distribución llamada '$backup_name'.${endColour}"
			sleep 3
		fi
	done


	mkdir -p "${path}/backup"
	if [ -d "${path}/backup/alias" ]; then
		for i in  $(ls ${path}/backup/alias); do
			local var=$(echo $i | tr -d '.txt')
			if [ "$backup_name" = $var ]; then
				echo -e "${msg2}${lightRed} Ya existe una copia creada con el nombre '${backup_name}'.${endColour}"
				exit 1
			fi
		done
	fi


	echo -e "${msg}${lightGreen} Creando copia en ${path}/backup/${backup_name}.tar.xz${endColour}"
	sleep 3
	if tar -cv --absolute-names -f - "$ruta" | xz -7 > "${path}/backup/$backup_name.tar.xz"; then
		echo -e "\n\n${msg}${lightGreen} La copia de seguridad ha sido creada correctamente.${endColour}"
		mkdir -p "${path}/backup/alias"
		echo $backup_name > "${path}/backup/alias/${backup_name}.txt"
	else
		echo -e "\n\n${msg2}${lightRed} No se pudo crear la copia de seguridad.${endColour}"
	fi

}


function command_restore() {
	banner
	echo -e "\n\n${msg}${lightBlueTwo} Restaurar una copia${endColour}"
	sleep 0.5
	local backup_name
	local count=1
	local vari=0


	function msg4() {
		echo -e "${lightGreen}[${lightRed}$1${lightGreen}] nombre${lightRed}:${green} $2${endColour}"
	}


	# Checamos si existe la copia
	if [ ! "$(ls ${path}/backup/alias 2> /dev/null)" ]; then
		echo -e "\n${msg2}${lightRed} No hay copias de seguridad creadas.${endColour}"
		exit 1
	fi


	echo -e "\n${msg}${lightGreen} Listando los backups creados.${endColour}"
	sleep 0.5


	for i in  $(ls ${path}/backup/alias); do
		local var=$(echo $i | tr -d '.txt')

		msg4 "$count" "$var"
		((count++))
		sleep 0.5
	done

	echo -e -n "\n${msg}${lightGreen} Introduzca el nombre de la copia a extraer${lightRed}:${green} "
	read backup_name

	for i in  $(ls ${path}/backup/alias); do
		local var=$(echo $i | tr -d '.txt')
		if [ $backup_name = $var ]; then
			vari+=1
		fi
	done


	if [ $vari -eq 1 ]; then
		if [ -d "${path}/rootfs/$backup_name" ]; then
			echo -e "\n${msg}${lightRed} Error: Ya exite una distro llamada '${backup_name}' instalada.${endColour}"
			exit 1
		fi
		echo -e "${msg}${lightGreen} Restaurando copia, por favor espere...${endColour}"
			tar -Jxf "${path}/backup/${backup_name}.tar.xz" --strip="1" -C "${path}/rootfs"

			# Restaura usuario.
			echo -e "${msg}${lightGreen} Restaurando usuario....${endColour}"
			sleep 1

			local username=`cat "${path}/rootfs/$backup_name/etc/details-distro/username.txt" 2>/dev/null`
			if [ -z $username ]; then
				echo -e "${msg}${lightRed} No se encontro ningun usuario para está copia. Se iniciara como Root.${endColour}"
			else
				mkdir -p "${path}/Alien/users/distro-${backup_name}"
				cp "${path}/rootfs/${backup_name}/etc/details-distro/username.txt" "${path}/Alien/users/distro-${backup_name}"
				echo -e "${msg}${lightGreen} Se encontro el usuario '${username}'. Se restauro correctamente${endColour}"
			fi
			echo -e "\n${msg}${lightGreen} La copia '${backup_name}' ha sido restaurado correctamente.${endColour}"

	else
		echo -e "\n${msg2}${lightRed} Error: no existe una copia con el nombre de $backup_name.${endColour}"
	fi
}


# Principal function.
function menu() {
	banner

	echo -e "\n"
	msg3 "1" "Instalar Debian 11 (bullseye)"
	msg3 "2" "Iniciar debian"
	msg3 "3" "Borrar uno distribición o una copia (backup)"
	msg3 "4" "Crear copia de seguridad"
	msg3 "5" "Restaurar copia de seguridad"
	msg3 "6" "Mostrar detalles de cada distribución"
	msg3 "7" "Salir"

	echo -e -n "\n${lightGreen}[${lightRed}~${lightGreen}]${darkGray} Seleccione una opción${lightRed}:${green} "
	read option

	case $option in
		"1")
		command_install;;

		"2")
		command_login;;

		"3")
		command_delete;;

		"4")
		command_backup;;

		"5")
		command_restore;;

		"6")
		echo "En desarollo";;

		"7")
		ctrl_c;;

		*)
		echo -e "\n${msg2} ${lightRed}Opción invalida.${endColour}"
	esac

}

# Execute the main function
menu
