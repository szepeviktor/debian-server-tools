<?php

class SiteInfo {

    /**
     * Site info.
     *
     * @var array
     */
    private static $info = array();

    /**
     * Set paths and URLs.
     *
     * Hook it to 'init' action at priority 100.
     *
     * @see https://codex.wordpress.org/Determining_Plugin_and_Content_Directories
     */
    public static function init() {
        $upload_path_and_url = wp_upload_dir();
        self::$info = [
            // Core
            'site_path'     => ABSPATH,
            'site_url'      => trailingslashit( site_url() ),
            'home_path'     => get_home_path(),
            'home_url'      => trailingslashit( get_home_url() ),
            'includes_path' => trailingslashit( ABSPATH . WPINC ),
            'includes_url'  => includes_url(),

            // Content
            'content_path' => trailingslashit( WP_CONTENT_DIR ),
            'content_url'  => trailingslashit( content_url() ),
            'uploads_path' => trailingslashit( $upload_path_and_url['basedir'] ),
            'uploads_url'  => trailingslashit( $upload_path_and_url['baseurl'] ),

            // Plugins
            'plugins_path' => trailingslashit( WP_PLUGIN_DIR ),
            'plugins_url'  => trailingslashit( plugins_url() ),

            // Themes
            'themes_root_path'  => trailingslashit( get_theme_root() ),
            'themes_root_url'   => trailingslashit( get_theme_root_uri() ),
            'parent_theme_path' => trailingslashit( get_template_directory() ),
            'parent_theme_url'  => trailingslashit( get_template_directory_uri() ),
            'child_theme_path'  => trailingslashit( get_stylesheet_directory() ),
            'child_theme_url'   => trailingslashit( get_stylesheet_directory_uri() ),
        ];
    }

    /**
     * @param string $name
     * @return string|null
     */
    public static function getPath( $name ) {
        $key = $name . '_path';
        if ( ! array_key_exists( $key, self::$info ) ) {
            return null;
        }
        return self::$info[ $key ];
    }

    /**
     * @param string $name
     * @return string|null
     */
    public static function getUrl( $name ) {
        $key = $name . '_url';
        if ( ! array_key_exists( $key, self::$info ) ) {
            return null;
        }
        return self::$info[ $key ];
    }

    /**
     * @param string $name
     * @return string|null
     */
    public static function getUrlBasename( $name ) {
        $url = self::getUrl( $name );
        if ( null === $url ) {
            return null;
        }
        return basename( $url );
    }

    /**
     * @return bool
     */
    public static function usingChildTheme() {
        return ( self::$info['parent_theme_path'] !== self::$info['child_theme_path'] );
    }

    /**
     * @return bool
     */
    public static function isUploadsWritable() {
        $uploadsDir = self::$info['uploads_path'];
        return file_exists( $uploadsDir ) && is_writeable( $uploadsDir );
    }
}
