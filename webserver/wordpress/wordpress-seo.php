<?php

// Disable JSON-LD - https://json-ld.org/
add_filter( 'wpseo_json_ld_output', '__return_empty_array' );
