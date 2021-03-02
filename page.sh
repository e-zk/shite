#!/bin/sh

. ${XDG_CONFIG_HOME:-${HOME}/.config}/shite/common.rc

gen_page() {
	post_file="$1"
	post_title="$2"
	post_content="$(run_lowdown "$(cat "$post_file")")"

	printf '<!DOCTYPE html>\n'
	printf '<html lang="en">\n'
	gen_head "$post_file" "${post_title}"
	printf '<body>\n'
	gen_nav
	printf '<main>\n'
	printf '%s\n'   "$post_content"
	printf '</main>\n'
	gen_footer "$post_file"
	printf '</body>\n'
	printf '</html>\n'
}

gen_page "$1" "$3" > "$2"
