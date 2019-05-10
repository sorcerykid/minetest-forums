#!/bin/awk -f

#######################################
#                                     #
#  Minetest Forum Recovery Project    #
#  by sorcerykid                      #
#                                     #
#######################################

# Generates a formatted HTML listing of forums from a tab-delimited digest
#
# Example usage:
#   % ./publish_forums.awk digest.txt > /var/www/html/forums/index.html

function print_header( ) {
        print( "<HTML>" );
        print( "<HEAD>" );
        print( "<TITLE>Minetest Forum Recovery Project</TITLE>" );
        print( "<STYLE>TH, TD, P, H1 { font-family: arial, helvetica; } P { font-size: 14px; } TD, TH { font-size: 16px; } H1 { font-size: 32px; } BIG { font-size: 24px; }</STYLE>" );
        print( "</HEAD>" );

        print( "<BODY><CENTER><DIV STYLE=\"width: 600px;\">" );
        print( "<H1 STYLE=\"margin-top: 0px;\"><IMG SRC=\"minetest-logo.png\" VSPACE=\"8\"><BR>Minetest Forum Recovery Project</H1>" );
        print( "<TABLE STYLE=\"border-style: solid; border-color: lightgrey; border-width: 2px;\" WIDTH=\"600\" CELLPADDING=\"6\" CELLSPACING=\"0\">" );
	print( "<TR><TH COLSPAN=\"3\"><BIG>Minetest Forums</BIG></TH></TR>" );
        print( "<TR BGCOLOR=\"lightgrey\"><TH WIDTH=\"80%\" ALIGN=\"left\">Forum Title</TH><TH WIDTH=\"10%\" ALIGN=\"left\">Topics</A></TH><TH WIDTH=\"10%\" ALIGN=\"left\">Posts</A></TH>" );
}

function print_footer( ) {
        print( "</TABLE>" );
        printf( "<P>Recovered %d posts, %d pages, and %d topics between March 13, 2019 and April 28, 2019</P>\n", total_posts, total_pages, total_topics );
        printf( "<P>Results generated on %s</P>\n", strftime( ) );
	print( "<P><A HREF=\"https://github.com/sorcerykid/minetest-forums/\">https://github.com/sorcerykid/minetest-forums/</A></P>" );
        print( "</DIV></CENTER></BODY>" );
        print( "</HTML>" );
}

function print_forum_entry( forum_title, forum_id ) {
	printf( "<TR><TD><A HREF=\"%s\">%s</A></TD><TD>%d</TD><TD>%d</TD>\n", forums[ forum_id ], forum_title, topic_totals[ forum_id ], post_totals[ forum_id ] );
}

BEGIN {
	FS = "\t";
	forums[ 18 ] = "news.html";
	forums[ 42 ] = "builds.html";
	forums[ 3 ] = "general_discussion.html";
	forums[ 5 ] = "feature_discussion.html";
	forums[ 6 ] = "problems.html";
	forums[ 10 ] = "servers.html";
	forums[ 11 ] = "mod_releases.html";
	forums[ 9 ] = "wip_mods.html";
	forums[ 47 ] = "modding_discussion.html";
	forums[ 15 ] = "game_releases.html";
	forums[ 49 ] = "game_discussion.html";
	forums[ 50 ] = "wip_games.html";
	forums[ 14 ] = "minetest_related_projects.html";
	forums[ 4 ] = "texture_packs.html";
	forums[ 12 ] = "maps.html";
}

{
	match( $2, /^pages\/([0-9]+)_([0-9]+)\.htm$/, res ) || match( $2, /^pages\/([0-9]+)_([0-9]+)_([0-9]+)\.htm$/, res );

	forum_id = res[ 1 ];
	topic_id = res[ 2 ];
	page_count = res[ 3 ] ? res[ 3 ] / 25 + 1 : 1;
	post_date = $4;

	if( match( post_date, /^... (...) (..), 2019/, res ) && ( res[ 1 ] == "Apr" || res[ 1 ] == "Mar" && res[ 2 ] > 12 ) ) {
		if( !has_topic[ topic_id ] ) {
			total_topics++;
			topic_totals[ forum_id ]++;
			has_topic[ topic_id ] = 1;
		}
		if( !has_page[ topic_id, page_count ] ) {
			total_pages++;
			has_page[ topic_id, page_count ] = 1;
		}

		total_posts++;
		post_totals[ forum_id ]++;
	}
}

END {
	print_header( );

	print_forum_entry( "News", 18 );
	print_forum_entry( "Builds", 42 );
	print_forum_entry( "General Discussion", 3 );
	print_forum_entry( "Feature Discussion", 5 );
	print_forum_entry( "Problems", 6 );
	print_forum_entry( "Servers", 10 );
	print_forum_entry( "Mod Releases", 11 ); 
	print_forum_entry( "WIP Mods", 9 );
	print_forum_entry( "Modding Discussion", 47 );
	print_forum_entry( "Game Releases", 15 );
	print_forum_entry( "Game Discussion", 49 );
	print_forum_entry( "WIP Games", 50 );
	print_forum_entry( "Minetest-related projects", 14 );
	print_forum_entry( "Texture Packs", 4 );
	print_forum_entry( "Maps", 12 );

	print_footer( );
}
