<?php
/**
 * Constructor parameters for O1_UTM
 *
 * @param string Host name for URL Builder.
 * @param array  Target website URL-s.
 *
 * Encode these URL parts:
 *     - international domain names (IDN encoding)
 *     - URL paths (URL encoding)
 *     - URL parameters (URL encoding)
 * WARNING! The code is error prone for encoding errors.
 * Target URL-s may contains query strings.
 */
new O1_UTM( 'utm.example.com', array(
    // error -> Site to redirect to in case of an error.
    'error'    => 'https://website.tld/',
    'site-reg' => 'https://web.site.tld/register/?key=new',
) );

/**
 * URL Builder for Google Analytics
 *
 * @version 0.2.3
 * @author Viktor Szépe <viktor@szepe.net>
 * @see https://support.google.com/analytics/answer/1033867 URL builder.
 */
final class O1_UTM {

    private $error_params = 'utm/honlap/festett-link-hiba';
    private $hostname;
    private $sites;

    public function __construct( $hostname = null, $sites = array() ) {

        // Security check
        $this->hostname = $hostname;
        $bad_request    = $this->bad_request();
        if ( false !== $bad_request ) {
            error_log( sprintf( 'Break-in attempt detected: %s %s',
                $bad_request,
                addslashes( isset( $_SERVER['REQUEST_URI'] ) ? $_SERVER['REQUEST_URI'] : '' )
            ) );
            ob_get_level() && ob_end_clean();
            if ( ! headers_sent() ) {
                header( 'Status: 403 Forbidden' );
                header( 'HTTP/1.1 403 Forbidden', true, 403 );
                header( 'Connection: Close' );
            }
            exit;
        }

        $this->sites = $sites;

        $url = $this->parse_path();
        if ( ! $url ) {
            $this->error();
        }

        $this->redirect( $url );
    }

    private function parse_path() {

        if ( ! is_array( $this->sites )
            || count( $this->sites ) < 1
            || empty( $_SERVER['REQUEST_URI'] )
        ) {

            return false;
        }

        $path = parse_url( $_SERVER['REQUEST_URI'], PHP_URL_PATH );
        // Remove first and last slashes
        $path = trim( $path, '/' );

        // 0 - site *
        // 1 - utm_source *
        // 2 - utm_medium *
        // 3 - utm_campaign *
        // 4 - utm_content (optional)
        // 5 - utm_term (optional)
        $parts = explode( '/', $path );

        // Minimum:  "site/source/medium/campaign"
        if ( count( $parts ) < 4 ) {

            return false;
        }

        // URL-decode and sanitize parts
        foreach ( $parts as $key => $part ) {
            $parts[ $key ] = filter_var( urldecode( $part ), FILTER_SANITIZE_STRING, FILTER_FLAG_STRIP_LOW );
        }

        // Non-existent site
        if ( ! array_key_exists( $parts[0], $this->sites ) ) {

            return false;
        }

        // Missing source, medium or campaign
        if ( empty( $parts[1] )
            || empty( $parts[2] )
            || empty( $parts[3] )
        ) {

            return false;
        }

        $query = array(
            'utm_source'   => $parts[1],
            'utm_medium'   => $parts[2],
            'utm_campaign' => $parts[3],
        );

        // Optional parameters (content and term)
        if ( ! empty( $parts[4] ) ) {
            $query['utm_content'] = $parts[4];
        }
        if ( ! empty( $parts[5] ) ) {
            $query['utm_term'] = $parts[5];
        }

        // PHP_QUERY_RFC3986 -> Google URL builder converts spaces to "%20"
        $query_string = http_build_query( $query, null, '&', PHP_QUERY_RFC3986 );

        // Site URL already contains query string
        $original_query = parse_url( $this->sites[ $parts[0] ], PHP_URL_QUERY );
        if ( empty( $original_query ) ) {
            $url_separator = '?';
        } else {
            $url_separator = '&';
        }

        $url = sprintf( '%s%s%s',
            $this->sites[ $parts[0] ],
            $url_separator,
            $query_string
        );

        return $url;
    }

    private function bad_request() {

        // Too big HTTP request URI
        // Apache: LimitRequestLine directive
        if ( strlen( $_SERVER['REQUEST_URI'] ) > 2000 ) {

            return 'bad_request_uri_length';
        }

        // Unknown HTTP request method
        $request_method = strtoupper( $_SERVER['REQUEST_METHOD'] );
        // Google Translate makes OPTIONS requests
        $utm_methods = array( 'GET', 'OPTIONS' );
        if ( false === in_array( $request_method, $utm_methods ) ) {

            return 'bad_request_http_method';
        }

        // Request URI does not begin with forward slash (may begin with URL scheme)
        if ( '/' !== substr( $_SERVER['REQUEST_URI'], 0, 1 ) ) {

            return 'bad_request_uri_slash';
        }

        // Request URI encoding
        // https://tools.ietf.org/html/rfc3986#section-2.2
        // reserved    = gen-delims / sub-delims
        // gen-delims  = ":" / "/" / "?" / "#" / "[" / "]" / "@"
        // sub-delims  = "!" / "$" / "&" / "'" / "(" / ")"
        //             / "*" / "+" / "," / ";" / "="
        // unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
        // "#" removed
        // "%" added
        if ( substr_count( $_SERVER['REQUEST_URI'], '?' ) > 1
            || false !== strpos( $_SERVER['REQUEST_URI'], '#' )
            || 1 === preg_match( "/[^%:\/?\[\]@!$&'()*+,;=A-Za-z0-9._~-]/", $_SERVER['REQUEST_URI'] )
        ) {

            return 'bad_request_uri_encoding';
        }

        // Hostname
        if ( empty( $_SERVER['HTTP_HOST'] ) || $this->hostname !== $_SERVER['HTTP_HOST'] ) {

            return 'bad_request_hostname';
        }

        // All OK
        return false;
    }

    private function redirect( $url ) {

        // Stolen from TinyURL's response
        header( 'Cache-Control: no-cache, private, no-store, max-age=0, s-maxage=0, must-revalidate, proxy-revalidate' );
        header( 'Expires: Wed, 04 Apr 1990 00:00:00 GMT' );
        header( 'Connection: close' );

        // Only temporarily redirection
        header( 'Location: ' . $url, true, 302 );

        exit;
    }

    private function error() {

        error_log( sprintf( 'UTM ERROR: %s',
            addslashes( isset( $_SERVER['REQUEST_URI'] ) ? $_SERVER['REQUEST_URI'] : '' )
        ) );
        if ( ! empty( $this->sites['error'] ) ) {
            printf( '<meta http-equiv="refresh" content="3;URL=https://%s/error/%s" />',
                $this->hostname,
                $this->error_params
            );
        }
        // 1F61E = Emoji Disappointed Face
        print '<h2>Sajnos a kért oldal nem található &#x1F61E;</h2>';
        exit;
    }
}
