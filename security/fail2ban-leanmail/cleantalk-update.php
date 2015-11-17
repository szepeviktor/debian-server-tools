<?php

/* grep "method_name\|createMsg" *
    - 2s_blacklists_db
    - check_message
    - check_newuser
    - spam_check

    - send_feedback
    - get_api_key
    - notice_paid_till
    - notice_validate_key

    - {"error_message":"Method name unset.","error_no":2}
    - {"error_message":"Data for validation not set.","error_no":8}

what to show: https://github.com/CleanTalk/html_templates/blob/master/spamfirewall.html

Shell
-----
Get IP-s:  sed -n 's/.* Ban \([0-9.]\+\)$/\1/p' /var/log/fail2ban.log

[ $(curl -s 'https://api.cleantalk.org/?method_name=spam_check&auth_key=amemeby2ujy2' -d "data=<ip>") == '{"data":{"<ip>":{"appears":1}}}' ]
#ct docs: https://cleantalk.org/wiki/doku.php
*/

$ct = new CleanTalkUpdate( 'amemeby2ujy2' );
$ct->in_range( $argv[1] );

class CleanTalkUpdate {

    private $user_agent = "Mozilla/5.0 (Linux) shell-f2b/1.0";
    private $api_url = 'https://api.cleantalk.org/';
    private $ranges = array();

    public function __construct( $access_key = '' ) {

        $get_query = array(
//            'method_name' => '2s_blacklists_db',
            'method_name' => 'spam_check',
            'auth_key' => $access_key
        );
        $post_data = array(
            'data' => '36.224.251.200'
        );
//        $response = $this->request( $post_data, $get_query );
// Cache in APC?
        $response = file_get_contents('2s_blacklists_db.json');

        if ( false === $response ) {
            return false; //????
        }

        $json = json_decode( $response );
        if ( NULL === $json || empty( $json->data ) ) {
            return false; //????
        }
        if ( isset( $json->error_message ) ) {
            //isset( $json->error_no )
            return false; //????
        }

        $this->ranges = $json->data;
    }

//    public function download_blacklist() {
//    public function spam_check( $ip ) {
    public function in_range( $ip ) {

        $ip_long = ip2long( $ip );
        foreach ( $this->ranges as $range ) {
            if ( count( $range ) !== 2 ) {
                return false;
            }
            /*$ip_octets = long2ip( $range[0] );
            if ( '0.0.0.0' === $range_octets ) {
            }
            $netmask = $this->mask2cidr( $range[1] );
            if ( 0 === $netmask ) {
            }*/
            $appears = $this->ip_in_range( $ip_long, $range[0], $range[1] );
            if ( $appears ) {
                var_dump($ip);
            }
        }
    }

    private function request( $post_data = array(), $get_query = null ) {

        $url = $this->api_url;
        if ( isset( $get_query ) ) {
            $url .= '?' . http_build_query( $get_query );
        }
        $ch = curl_init();
        curl_setopt( $ch, CURLOPT_URL, $url );
        curl_setopt( $ch, CURLOPT_TIMEOUT, 10 );
        curl_setopt( $ch, CURLOPT_SSL_VERIFYPEER, true );
        curl_setopt( $ch, CURLOPT_SSL_VERIFYHOST, 2 );

        curl_setopt( $ch, CURLOPT_FOLLOWLOCATION, false );
        curl_setopt( $ch, CURLOPT_RETURNTRANSFER, true );
        curl_setopt( $ch, CURLOPT_POST, true );
        curl_setopt( $ch, CURLOPT_POSTFIELDS, $post_data );
        curl_setopt( $ch, CURLOPT_USERAGENT, $this->user_agent );

        $output = curl_exec( $ch );
//        curl_error($ch) curl_errno($ch) ??as json? error_message error_no, msg-prefix:_curl_
        curl_close( $ch );

        return $output;
    }

    private function mask2cidr( $netmask ) {

        return 32 - log( ( $netmask ^ 4294967295 ) + 1, 2 );
    }

    private function ip_in_range( $ip, $range, $netmask ) {

        return ( ( $ip & $netmask ) === ( $range & $netmask ) );
    }
}
