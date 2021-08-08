#!/bin/sh
set -e

env="${1:-./.env}"
# shellcheck source=./.env.template
. "$env"

exclude_files="${exclude_files}"
meta_ext="${meta_ext:-.meta}"
site_root="${site_root}"
html_dir="${html_dir:-html}"
post_dir="${post_dir:-posts}"

log() {
	printf 'shite: [%s] %s\n' "$1" "$2" >&2
}
info() {
	log "$(printf '\033[32minfo\033[0m')" "$1"
}
warn() {
	log "$(printf '\033[33mwarn\033[0m')" "$1"
}
error() {
	log "$(printf '\033[31merror\033[0m')" "$1"
}
die() {
	error "$1"
	printf 'exiting...\n' >&2
	exit 1
}

gen_header() {
	printf '<header>\n'
	printf '<nav>\n'
	if [ -f "${site_root}/${html_dir}/header.html" ]; then
		cat "${site_root}/${html_dir}/header.html"
	else
		warn "header_content file 'header.html' does not exist."
	fi
	printf '</nav>\n'
	printf '</header>\n'
}
gen_index_head() {
	cat "${html_dir}/index_head.html"
}
gen_index_tail() {
	cat "${html_dir}/index_tail.html"
}

gen_index() {
	find "${site_root}/${post_dir}/" -name '*.md' | while read -r post; do
		post_html="${post%.*}.html"
		post_meta="${post%.*}${meta_ext}"
		post_url="/posts/$(basename "$post_html")"

		excluded=0
		for ex in $exclude_files; do
			if [ "$(basename "$post")" = "$ex" ]; then
				excluded=1
			fi
		done
	
		if [ "$excluded" -eq 1 ]; then
			warn "${post} excluded"
			continue
		fi
	
		# parse metadata if .meta file exists
		if [ -f "$post_meta" ]; then
			# read the 'key: value' .meta file
			while IFS=': ' read -r key val; do
				[ "${key##\#*}" ] || continue
				# export each key as a variable; '$post_<key>'
				export "post_${key}=${val}" 2>/dev/null || \
					warn "'${key}' is not a valid meta tag name"
			done < "$post_meta"
		else
			warn "no ${meta_ext} - skipping metadata parsing"
		fi
	
		echo "${post_date}|${post_title}|${post_url}" >> index.meta
	
		unset post_date
		unset post_title
		unset post_image
		unset post_description
		unset post_url
	done
	
	printf '<!DOCTYPE html>\n'
	printf '<html>\n'
	printf '<head>\n'
	printf "<title>zakaria's web log</title>\n"
	cat "${html_dir}/head.html"
	printf "<meta property=\"og:title\" content=\"zakaria's web log\">\n"
	printf '</head>\n'
	printf '<body>\n'
	gen_header
	gen_index_head
	sort -r index.meta | while IFS='|' read -r post_date post_title post_url; do
		printf '<p class="postitem"><a href="%s"><span class="postdate">%s</span>%s</a></p>\n' "$post_url" "$post_date" "$post_title"
	done
	gen_index_tail
	printf '</body>\n'
	printf '</html>\n'
}

if [ -f "./index.meta" ]; then
	log 'old index.meta file found. remove?'
	rm -i "./index.meta"
fi

gen_index > "${site_root}/${post_dir}/index.html"

# remove index tempfile
rm -i index.meta
