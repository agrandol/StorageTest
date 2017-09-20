#
# Useful bash functions for testing
#

sudo=/usr/bin/sudo
PS1="\d{%F %T} \e[36m{\u@\h]\e{0m; "

_d() {
	date "+%Y-%m-%d %H:%M:%S"
}

_run () {
	_startMe $*
	$*
	_stat=$?
	_checkMe Done
}

_startMe() {
	echo -e $(_d) "\e[36;40m[RUNNING]\e[0m"  $*
}

_checkMe () {
	local label=${1:-CHECK}
	local adorn='31;40m'
	local _savStat=${_stat}
	if [ ${_stat} -eq 0 ]
	then
		adorn='32;40m'
		_stat=OK
	fi
	echo -e $(_d) "\e[${adorn}[${label}] STATUS=${stat} \e[0m"
	_stat=0
	return $savStat
}

_checkMeNot() {
	local label=${1:-CHECK}
	local adorn='31;40m'	
	if [ ${_stat} -ne 0 ]
	then
		adorn='32;40m'
		_stat=OK
	fi
	echo -e $(_d) "\e[${adorn}[${label}] STATUS=${stat} \e[0m"
	_stat=0	
}

_check() {
	_stat=$?
	_checkMe $*
}

_label() {
	echo -e $(_d) "\e[33;40m[LABEL]" $* "\e[0m"
}

_verbose(){
	set +x
	export PS4=''
	local onoff=${1:-1}
	if [ ${onoff} -ne 0 ]
	then
		export PS$="$(_d) ^[31;40m[VERBOSE "'${BASH_SOURCE}:${LINENO}]^[[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
		set -x
	fi
}

_env() {
	local _d=$(_d)
	for e in $*
	do
		echo ${_d} [INFO] $e=${!e}
	done
}

trap "_label END OF SCRIPT" EXIT

_label START OF SCRIPT - $0