<?php declare( strict_types = 1 );
/**
 * Strongly typed Advanced Custom Fields get_field function variants.
 *
 * @package ACFget
 * @version 0.1.0
 */

/**
 * Helper functions for getting strictly typed ACF field values.
 */
class ACFget {

	/**
	 * The post ID of which the value is saved against.
	 *
	 * @var int|string|false
	 */
	public static $post_id = false;

	/**
	 * Return custom field value as an string.
	 *
	 * @param string $selector
	 * @param string $default
	 * @return string
	 */
	public static function string_field( string $selector, string $default = '' ) : string {
		$raw_value = \get_field( $selector, static::$post_id );
		return ( null === $raw_value ) ? $default : $raw_value;
	}

	/**
	 * Return custom field value as an integer.
	 *
	 * @param string $selector
	 * @param int $default
	 * @return int
	 */
	public static function int_field( string $selector, int $default = 0 ) : int {
		$raw_value = \get_field( $selector, static::$post_id );
		return ( null === $raw_value ) ? $default : intval( $raw_value );
	}

	/**
	 * Return custom field value as a floating point number.
	 *
	 * @param string $selector
	 * @param float $default
	 * @return float
	 */
	public static function float_field( string $selector, float $default = 0.0 ) : float {
		$raw_value = \get_field( $selector, static::$post_id );
		return ( null === $raw_value ) ? $default : floatval( $raw_value );
	}

	/**
	 * Return custom field value as a boolean.
	 *
	 * @param string $selector
	 * @param bool $default
	 * @return bool
	 */
	public static function bool_field( string $selector, bool $default = false ) : bool {
		$raw_value = \get_field( $selector, static::$post_id );
		return ( null === $raw_value ) ? $default : boolval( $raw_value );
	}

	/**
	 * Return custom field value as a boolean or null.
	 *
	 * @param string $selector
	 * @param bool|null $default
	 * @return bool|null
	 */
	public static function trinary_field( string $selector, bool $default = null ) {
		$raw_value = \get_field( $selector, static::$post_id );
		return ( null === $raw_value ) ? $default : boolval( $raw_value );
	}

	/**
	 * Return custom field value as an array.
	 *
	 * @param string $selector
	 * @param array $default
	 * @return array
	 */
	public static function array_field( string $selector, array $default = [] ) : array {
		$raw_value = \get_field( $selector, static::$post_id );
		if ( is_array( $raw_value ) ) {
			return $raw_value;
		}
		return ( null === $raw_value ) ? $default : [ $raw_value ];
	}

	/**
	 * Return custom field value as instance of WP_Post.
	 *
	 * @param string $selector
	 * @return \WP_Post|null
	 */
	public static function post_field( string $selector ) {
		$raw_value = \get_field( $selector, static::$post_id );
		if ( is_object( $raw_value ) && is_a( $raw_value, '\WP_Post', false ) ) {
			return $raw_value;
		}
		// TODO Need a better way.
		return null;
	}
}

/* TODO New types
Email
Url
Password

Image
File
Wysiwyg Editor
oEmbed
Gallery

Select
Checkbox
Radio Button
Button Group
True / False

Link
Page Link
Relationship
Taxonomy
User

Google Map
Date Picker
Date Time Picker
Time Picker
Color Picker

Message
Accordion
Tab
Group
Repeater
Flexible Content
Clone
*/
