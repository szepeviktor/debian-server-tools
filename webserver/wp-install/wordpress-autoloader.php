<?php
/**
 * Autoloader for WordPress.
 *
 * @package CompanyProject
 * @link https://make.wordpress.org/core/handbook/best-practices/coding-standards/php/#naming-conventions
 * @link https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-4-autoloader-examples.md#class-example
 */

declare( strict_types = 1 );

namespace Company\Project;

use function spl_autoload_register;

spl_autoload_register(
	/**
	 * Closure of the autoloader.
	 *
	 * @param class-string $class_name The fully-qualified class name.
	 * @return void
	 */
	static function ( $class_name ) {
		/**
		 * __NAMESPACE__ could be an empty string.
		 *
		 * @phpstan-ignore-next-line
		 */
		$project_namespace = '' === __NAMESPACE__ ? '' : __NAMESPACE__ . '\\';
		$length            = strlen( $project_namespace );

		// Class is not in our namespace.
		if ( 0 !== strncmp( $project_namespace, $class_name, $length ) ) {
			return;
		}

		// E.g. Model\Item.
		$relative_class_name = substr( $class_name, $length );
		// Class file names should be based on the class name with "class-" prepended
		// and the underscores in the class name replaced with hyphens.
		// E.g. model/class-item.php.
		$name_parts = explode( '\\', strtolower( str_replace( '_', '-', $relative_class_name ) ) );
		$last_part  = array_pop( $name_parts );

		$file = sprintf(
			'%1$s/includes%2$s/class-%3$s.php',
			__DIR__,
			array() === $name_parts ? '' : '/' . implode( '/', $name_parts ),
			$last_part
		);

		if ( ! is_file( $file ) ) {
			return;
		}

		require $file;
	}
);
