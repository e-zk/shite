#!/bin/sh

env="${1:-./.env}"
# shellcheck source=./.env.template
. "$env"

exclude_files="${exclude_files}"
meta_ext="${meta_ext:-.meta}"
site_root="${site_root}"
html_dir="${html_dir:-html}"
post_dir="${post_dir:-posts}"

rss_root="${rss_root}"
rss_title="${rss_title}"
rss_description="${rss_description}"
rss_link="${rss_link}"

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

# convert input date to RFC2822
# time and tz are set to 00:00:00 +0000
# $1 - input date
to_rfc2822() {
        date="$1"
        format="%F"
        rfc2822="+%a, %d %b %Y 00:00:00 +0000"

        # if on Linux, use GNU date syntax
        if [ "$(uname)" = "Linux" ]; then
                date -d "$date" "$rfc2822"
        else
                date -j -f "$format" "$date" "$rfc2822"
        fi
}

rss_preamble() {
	printf '<rss version="2.0" xml:base="%s">\n' "$rss_root"
	printf '<channel>\n'
	printf '<title>%s</title>\n' "$rss_title"
	if [ -n "$rss_description" ]; then
		printf '<description>\n'
		printf '%s\n' "$rss_description"
		printf '</description>\n'
	else
		printf '<description/>\n'
	fi
	printf '<link>%s</link>\n' "$rss_link"
}

rss_postamble() {
	printf '</channel>\n'
	printf '</rss>\n'
}

gen_rss() {
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
	
		echo "${post_date}|${post_title}|${post_url}|${post}" >> rss.meta

		unset post_date
		unset post_title
		unset post_image
		unset post_description
		unset post_url
	done

	rss_preamble
	sort -r rss.meta | while IFS='|' read -r post_date post_title post_url post_md; do
		[ -z "$post_date" ] && continue
		rfcdate="$(to_rfc2822 "$post_date")"
		printf '<item>\n'
		printf '<link>%s%s</link>\n' "$rss_root" "$post_url"
		printf '<title>%s</title>\n' "$post_title"
		printf '<pubDate>%s</pubDate>\n' "$rfcdate"
		printf '<description>\n'
		lowdown -Thtml < "$post_md"
		printf '</description>\n'
		printf '</item>\n'
	done
	rss_postamble
}

gen_rss
rm -i rss.meta
