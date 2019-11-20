<?php
/**
 * Plugin Idea: 404 Intelligence
 */

// Publish on WP.org

# $ wp post list --format=ids --post_type=page --menu_order=404

// Hook before determining which template to load.
// Skip for robots!
add_action( 'template_redirect', 'set_custom_isvars', 10, 0 );
// move to 'pre_get_posts' + is_main_query() ???

function set_custom_isvars() {
	global $wp_query;
	if (!is_404()) return;

	echo '<pre>'; var_dump($wp_query->query);

	// Post type identified!
	if ( ! empty( $wp_query->query['post_type'] ) ) {
		$post_type = $wp_query->query['post_type'];
		// Allow custom actions.
		do_action( "404_intel_post_type_{$post_type}", $wp_query );
/*
Post type identified:
- Search for similar posts in the same post type
- search all words, support relevanssi https://wordpress.org/plugins/relevanssi/
- in posts and pages
- search all words
- do_action()

Post type not identified:
- do_action()
- "." static file -> image? -> 42-byte GIF
- "/feed/" -> empty XML
- search all words
- do_action()

(Add to custom actions: REQUIRE)
*/
		if ( ! empty( $wp_query->query['name'] ) ) {
			$slug = $wp_query->query['name'];

//move to a search method($term) return count($results);
			$results = query_posts( [
				'post_type' => $post_type,
				's' => $slug,
			] );
			// If not found try next search.
			// /_-/ / + explode()
			if ( [] === $results ) {
				wp_reset_query();
			}

			// Use our custom templates for displaying results: 404item-$posttype.php + 404item.php
			$templates = add_filter( 'search_template_hierarchy', $templates );
			return;
		}
		switch ( $post_type ) {
			case 'post':
				// ...
				break;
			case 'page':
				// ...
				break;
			default:
				// Custom Post Type
				break;
		}
	}
	// if('post_type') 'offer' 'name'->Post slug
}

/*
- remove query string
- exclude URLs: with dot ".", admin, WP_INC, WP_CONTENT, $author prefix, apply_filters:"/profile/"
- adaptive 404
- select 404 page, default:page with slug "404" filter:"fix_404_page_id"
- robot 404 -> no content

1. sanitize_title() + '/[_-]/ /g'
1. search: post, page, apply_filters:CPT, tag, cat, apply_filters:taxonomy, exclude posts, terms
   - no results -> detect CPT/taxonomy URL -> apply_filters:redirect to URL (e.g. post->/blog/)
     "fix_404_target_url_post_type_{$cpt}" "fix_404_target_url_taxonomy_{$tax}"
   - only 1 result -> temp redirection
   - more results -> display

https://wordpress.org/plugins/tags/404/

https://wordpress.org/plugins/wp-404-auto-redirect-to-similar-post/
https://plugins.trac.wordpress.org/browser/wp-404-auto-redirect-to-similar-post/

https://wordpress.org/plugins/permalink-finder/
*/
