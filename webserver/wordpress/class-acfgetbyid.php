<?php declare( strict_types = 1 ); // phpcs:disable NeutronStandard.MagicMethods.RiskyMagicMethod.RiskyMagicMethod
/**
 * Strongly typed Advanced Custom Fields get_field function variants with post ID.
 *
 * @package ACFget
 * @version 0.1.0
 */

/**
 * Helper functions for getting strictly typed ACF field values by post ID.
 */
class ACFgetbyid {

	/**
	 * Set post ID and call method of ACFget.
	 *
	 * Example: ACFgetbyid::some_field( $selector, $post_id [, $default] );
	 *
	 * @param string $name Method name.
	 * @param array $arguments Arguments for the method.
	 * @return mixed
	 * @throws \Exception
	 */
	public static function __callStatic( string $name, array $arguments ) {
		// Check static method name and arguments.
		if ( ! method_exists( 'ACFget', $name ) ) {
			throw new \Exception( sprintf( 'Method does not exist: ACFget::%s', $name ) );
		}
		$arg_count = count( $arguments );
		if ( $arg_count !== 2 && $arg_count !== 3 ) {
			throw new \Exception( sprintf( 'ACFget::%s needs 2 or 3 arguments.', $name ) );
		}

		$previous_post_id = ACFget::$post_id;
		ACFget::$post_id = $arguments[1];
		if ( 2 === $arg_count ) {
			// $selector only
			// phpcs:ignore NeutronStandard.Functions.VariableFunctions.VariableFunction
			$return_value = ACFget::$name( $arguments[0] );
		}
		if ( 3 === $arg_count ) {
			// $selector and $default
			// phpcs:ignore NeutronStandard.Functions.VariableFunctions.VariableFunction
			$return_value = ACFget::$name( $arguments[0], $arguments[2] );
		}
		// Restore post ID
		ACFget::$post_id = $previous_post_id;

		return $return_value;
	}
}
