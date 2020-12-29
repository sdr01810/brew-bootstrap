#!/bin/bash
## Bootstrap the installation of (Home)brew packages, by provisioning brew itself.
## By Stephen D. Rogers <inbox.c7r@steve-rogers.com>
##
## Installs Homebrew, and then a standard set of taps, extensions, formulas, and bundles.
##
## Arguments:
##
##    None.
##
## Typical use:
##
##    brew-bootstrap.sh
##
## Known bugs & limitations:
##
##    Only installs Homebrew to `/usr/local`. This is a limitation of the standard Homebrew installation script.
##
##    Only tested on mac OS, even though Homebrew now supports other platforms.
##

set -e

set -o pipefail 2>&- || :

this_script_pnp="${0%.*sh}"
this_script_fbn="$(basename "$0")"
this_script_stem="${this_script_fbn%.*sh}"

this_script_dpn="$(cd "$(dirname "$0")" && pwd -P)"

this_package_dpn="$(cd "$(dirname "${this_script_dpn}")" && pwd -P)"

##
## configuration:
##

BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_DPN="/usr/local" # do not change; presumed by the bootstrapping installation script

BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_BACKUP_FBN=".sb.brew-bootstrap.before.tar.gz" # relative to installation root

BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_BACKUP_FPN="${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_DPN%/}/${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_BACKUP_FBN:?}"

#

BREW_BOOTSTRAP_POLICY_ALWAYS_DOWNLOAD_PACKAGE_BREW_INSTALLATION_SCRIPTS= #

BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_SCRIPT_PNP="${this_script_dpn%/}/${this_script_stem:?}.cached.installation"

BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_REDO_SCRIPT_SUFFIX=".redo.rb"
BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_UNDO_SCRIPT_SUFFIX=".undo.rb"

BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_REDO_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/master/install"
BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_UNDO_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/master/uninstall"

##

BREW_BOOTSTRAP_STANDARD_BREW_TAP_LIST=(

	homebrew/bundle

	homebrew/cask
	homebrew/cask-versions

	homebrew/core
)

##

BREW_BOOTSTRAP_STANDARD_BREW_EXTENSION_LIST=(

	bundle

	cask
)

##

BREW_BOOTSTRAP_STANDARD_BREW_FORMULA_LIST=(

	mas

	pkg-config
)

##

BREW_BOOTSTRAP_STANDARD_BREW_BUNDLE_LIST=(

	"${this_package_dpn:?}/etc/${this_script_stem:?}".conf.initial-bundle
)

[ "${#BREW_BOOTSTRAP_STANDARD_BREW_BUNDLE_LIST[@]}" -gt 0 ]

##
## from snippets library:
##

function xx() { # ...

	echo 1>&2 "+" "$@"
	"$@"
}

function without_output() { # ...

	"$@" >/dev/null 2>&1
}

function without_interaction() { # ...

	"$@" </dev/null
}

function briefly_cache_sudo_authentication() { # ...

	sudo true # side effect: briefly caches sudo authentication
}

function install_brew_tap() { # [tap_name ...]

	local tap_name_list=( "$@" )
	local x1

	##

	for x1 in "${tap_name_list[@]}" ; do

		xx :
		xx brew tap "${x1}"
	done
}

function install_brew_extension() { # [extension_name ...]

	local extension_name_list=( "$@" )
	local x1

	##

	for x1 in "${extension_name_list[@]}" ; do

		xx :
		xx without_output brew "${x1}" --help
		xx : "^-- side effect: installs extension '${x1}'"
	done
}

function install_brew_formula() { # [formula_name ...]

	local formula_name_list=( "$@" )
	local x1

	##

	for x1 in "${formula_name_list[@]}" ; do

		xx :
		xx brew install "${x1}"
	done
}

function install_brew_bundle() { # [bundle_name ...]

	local bundle_name_list=( "$@" )
	local x1

	##

	for x1 in "${bundle_name_list[@]}" ; do

		xx :
		xx brew bundle install --file="${x1}"
	done
}

##
## core logic:
##

function check_package_brew_installation_root() { # installation_root_dpn

	local installation_root_dpn="${1:?}" ; shift

	[ $# -eq 0 ]

	##

	case "${installation_root_dpn:?}" in
	/*)
		true
		;;
	*)
		echo 1>&2 "Must be absolute (not relative) path: ${installation_root_dpn:?}"
		(false ; return)
		;;
	esac

	! [ -L "${installation_root_dpn:?}" ] || {

		echo 1>&2 "Must be directory (not symbolic link): ${installation_root_dpn:?}"
		(false ; return)
	}

	[ -d "${installation_root_dpn:?}" ] || {

		echo 1>&2 "Must be directory (created already): ${installation_root_dpn:?}"
		(false ; return)
	}
}

function download_package_brew_installation_script_to() { # script_destination_fpn script_url

	local script_destination_fpn="${1:?}" ; shift
	local script_url="${1:?}" ; shift

	[ $# -eq 0 ]

	##

	xx :
	xx curl -fsSL "${script_url:?}" > "${script_destination_fpn:?}"
}

function ensure_download_of_package_brew_installation_script() { # script_destination_fpn script_url

	local script_destination_fpn="${1:?}" ; shift
	local script_url="${1:?}" ; shift

	[ $# -eq 0 ]

	##

	! [ -n "${BREW_BOOTSTRAP_POLICY_ALWAYS_DOWNLOAD_PACKAGE_BREW_INSTALLATION_SCRIPTS}" ] || {

		> "${script_destination_fpn:?}"
	}

	[ -s "${script_destination_fpn:?}" ] || {

		download_package_brew_installation_script_to "${script_destination_fpn:?}" "${script_url:?}"

		xx :
		xx chmod a+rx "${script_destination_fpn:?}"
	}
}

function backup_package_brew_installation_root_to() { # backup_destination_fpn installation_root_dpn

	local backup_destination_fpn="${1:?}" ; shift
	local installation_root_dpn="${1:?}" ; shift

	[ $# -eq 0 ]

	##

	local backup_destination_fpn_exclusion_pattern="${backup_destination_fpn#${installation_root_dpn%/}/}"

	(cd "${installation_root_dpn:?}"

		xx :
		xx sudo tar czf "${backup_destination_fpn:?}" --exclude "${backup_destination_fpn_exclusion_pattern:?}" .
	)
}

function ensure_backup_of_package_brew_installation_root() { # installation_root_dpn backup_destination_fpn

	local installation_root_dpn="${1:?}" ; shift
	local backup_destination_fpn="${1:?}" ; shift


	[ $# -eq 0 ]

	##

	[ -s "${backup_destination_fpn:?}" ] ||
	backup_package_brew_installation_root_to "${backup_destination_fpn:?}" "${installation_root_dpn:?}"
}

function install_package_brew() { #

	local pnp="${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_SCRIPT_PNP:?}"

	local package_brew_installation_redo_script_fpn="$(echo \
		"${pnp:?}${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_REDO_SCRIPT_SUFFIX:?}"
	)"
	local package_brew_installation_undo_script_fpn="$(echo \
		"${pnp:?}${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_UNDO_SCRIPT_SUFFIX:?}"
	)"

	##

	check_package_brew_installation_root \
		"${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_DPN:?}" #

	##

	briefly_cache_sudo_authentication

	ensure_backup_of_package_brew_installation_root \
		"${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_DPN:?}" \
		"${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_ROOT_BACKUP_FPN:?}" #

	ensure_download_of_package_brew_installation_script \
		"${package_brew_installation_redo_script_fpn:?}" \
		"${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_REDO_SCRIPT_URL:?}" #

	ensure_download_of_package_brew_installation_script \
		"${package_brew_installation_undo_script_fpn:?}" \
		"${BREW_BOOTSTRAP_PACKAGE_BREW_INSTALLATION_UNDO_SCRIPT_URL:?}" #

	xx :
	xx without_interaction /usr/bin/ruby "${package_brew_installation_redo_script_fpn:?}"
}

function install_standard_brew_taps() { #

	xx :
	xx install_brew_tap "${BREW_BOOTSTRAP_STANDARD_BREW_TAP_LIST[@]}"
}

function install_standard_brew_extensions() { #

	xx :
	xx install_brew_extension "${BREW_BOOTSTRAP_STANDARD_BREW_EXTENSION_LIST[@]}"
}

function install_standard_brew_formulas() { #

	xx :
	xx install_brew_formula "${BREW_BOOTSTRAP_STANDARD_BREW_FORMULA_LIST[@]}"
}

function install_standard_brew_bundles() { #

	xx :
	xx install_brew_bundle "${BREW_BOOTSTRAP_STANDARD_BREW_BUNDLE_LIST[@]}"
}

function create_brew_bootstrap_bundle { # [--provide-parting-advice]

	local brew_global_bundle_fpn="${HOME:?}"/.Brewfile
	local brew_bootstrap_bundle_fpn="${brew_global_bundle_fpn:?}".bootstrap

	local provide_parting_advice_p=

	while [ $# -gt 0 ] ; do

		case "${1}" in
		--provide-parting-advice)
			provide_parting_advice_p=t
			shift
			;;
		--)
			shift
			break
			;;
		*)
			break
			;;
		esac
	done

	[ $# -eq 0 ]

	##

	local brew_bundle_dump_action_performed="Created"

	if [ -e "${brew_bootstrap_bundle_fpn:?}" ] ; then

		brew_bundle_dump_action_performed="Updated existing"
	fi

	xx :
	xx cp "${BREW_BOOTSTRAP_STANDARD_BREW_BUNDLE_LIST[0]:?}" "${brew_bootstrap_bundle_fpn:?}" || return $?

	if [ -n "${provide_parting_advice_p}" ] ; then

		echo 1>&2
		echo 1>&2 "${brew_bundle_dump_action_performed:?} brew bundle file: ${brew_bootstrap_bundle_fpn:?}"

		if [ "${brew_bootstrap_bundle_fpn:?}" != "${brew_global_bundle_fpn:?}" ] ; then
		echo 1>&2
		echo 1>&2 "Use it as a starting point for your global bundle file: ${brew_global_bundle_fpn:?}"
		fi
		echo 1>&2
		echo 1>&2 "For details, see the $(brew bundle --help)"
	fi
}

function main() { # ...

	install_package_brew "$@"

	install_standard_brew_taps

	install_standard_brew_extensions

	install_standard_brew_formulas

	install_standard_brew_bundles

	create_brew_bootstrap_bundle --provide-parting-advice
}

! [ "$0" = "${BASH_SOURCE:?}" ] || main "$@"

