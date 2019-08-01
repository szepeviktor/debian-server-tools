<?php
/**
 * This is a gift for Phil.
 *
 * Usage: $db = new \WordPress\WpDb(); $db->prepare('...');
 */

declare( strict_types = 1 );

namespace WordPress;

/**
 * Connect to global $wpdb instance from proper OOP code.
 *
 * @see https://www.php.net/manual/en/language.oop5.magic.php
 */
class WpDb {

    /**
     * Get a property.
     *
     * @see https://codex.wordpress.org/Class_Reference/wpdb#Class_Variables
     * @param string $name
     * @return mixed
     */
    public function __get( $name ) {
        global $wpdb;

        return $wpdb->$name;
    }

    /**
     * Noop on set.
     *
     * @param string $name
     * @param mixed $value
     * @return void
     */
    public function __set( $name, $value ) {}

    /**
     * Execute a method.
     *
     * @see https://www.php.net/manual/en/language.oop5.overloading.php#object.call
     * @param string $name
     * @param array $arguments
     * @return mixed
     */
    public function __call( $name, $arguments ) {
        global $wpdb;

        return call_user_func_array( [ $wpdb, $name ], $arguments );
    }
}
