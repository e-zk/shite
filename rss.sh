#!/bin/sh
# rss feed generator


. ${XDG_CONFIG_HOME:-${HOME}/.config}/shite/common.rc

exclude_fnames="${exclude_fnames:-index.html index.md}"
rss_baseurl="${base_url}/"
rss_title="${site_name}"
rss_link="${base_url}/posts/"

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
	printf '<rss version="2.0" xml:base="%s">\n' "$rss_baseurl"
	printf '<channel>\n'
	printf '<title>%s</title>\n' "$rss_title"
	printf '<description/>\n' # TODO add description?
	printf '<link>%s</link>\n' "$rss_link"
}

rss_postamble() {
	printf '</channel>\n'
	printf '</rss>\n'
}

# remove markdown from title
remove_md() {
	sed 's/`//g'
}

reverse_posts() {
	break=0
	posts=''
	for file in ${site_root}/${posts_dir}/*.html; do
		base="$(basename "$file")"
		for ex in ${exclude_fnames}; do
			[ "$base" = "$ex" ] && break=1
		done
		[ "$break" -eq 1 ] && continue
		posts="${posts}\\n${file}"
	done
	echo "$posts" | tail -r
}

rss_preamble
for file in $(reverse_posts); do
	post_bname="$(basename "$file")"
	md="${file%%.*}.md"

	parsed="$(parse_fname "$post_bname")"

	post_date="$(to_rfc2822 "${parsed%%:*}")"
	post_title="$(md_title "$md" | remove_md)"

	log "adding \"${post_title}\" @ ${post_date}..."

	printf '<item>\n'
	printf '<link>%s/posts/%s</link>\n' "$base_url" "$post_bname"
	printf '<title>%s</title>\n' "$post_title"
	printf '<pubDate>%s</pubDate>\n' "$post_date"
	printf '<description>\n'
	lowdown ${lowdown_opts} "$md"
	printf '</description>\n'
	printf '</item>\n'
done
rss_postamble
