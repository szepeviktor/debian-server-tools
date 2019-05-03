<?php declare( strict_types = 1 );
/**
 * Strongly typed Advanced Custom Fields get_field function variants for options.
 *
 * @package ACFget
 * @version 0.1.0
 */

/**
 * Helper functions for getting strictly typed ACF option values.
 */
class ACFoption extends ACFget {

	/**
	 * The post ID of which the value is saved against.
	 *
	 * @var int|string|false
	 */
	public static $post_id = 'options';
}
