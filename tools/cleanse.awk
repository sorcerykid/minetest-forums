#!/bin/awk -f

#######################################
#                                     #
#  Minetest Forum Recovery Project    #
#  by sorcerykid                      #
#                                     #
#######################################

# Strip highlighting from cached page inserted by Yandex search engine.
#
# Usage with single cached page:
#   % ./cleanse.awk cache/3_1568.htm

function strip_highlights( ) {
	$0 = gensub( /<a name='YANDEX_[0-9]+'><\/a>&nbsp;<span class='highlight highlight_active'>&nbsp;/, "", "g" );
	$0 = gensub( /&nbsp;<\/span><a href='[^#]+#YANDEX_[0-9]+'><\/a><\/nobr>/, "", "g" );
        $0 = gensub( /&nbsp;<\/span><\/A><a href='[^#]+#YANDEX_[0-9]+'><\/a><\/nobr>/, "", "g" );

        $0 = gensub( /<a name='YANDEX_[0-9]+'><\/a><nobr><a href='[^#]+#YANDEX_[0-9]+'><\/a><a href="[^"]+">/, "", "g" );
        $0 = gensub( /<a name='YANDEX_[0-9]+'><\/a><nobr><a href='[^#]+#YANDEX_[0-9]+'><\/a>/, "", "g" );
        $0 = gensub( /<span class='highlight highlight_active'>&nbsp;/, "", "g" );
        $0 = gensub( /&nbsp;<\/span><a name='YANDEX_LAST'><\/a>/, "", "g" );
        $0 = gensub( /<script src="\/\/yandex.st\/.+" type="text\/javascript"><\/script>/, "", "g" );
        $0 = gensub( /<a name='yandex_top'><\/a><script>.+<\/script>/, "", "g" );
}

{
	strip_highlights( );
	print( $0 );
}
