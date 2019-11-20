<?php

add_action( 'wp_footer', function () {

?>
<script>
// Display page load time.
// https://www.stevesouders.com/blog/2014/08/21/resource-timing-practical-tips/
window.onload = function () {
    "use strict";
    // EDIT
    var selector = ".welcome-msg";
    var t = window.performance.timing;
    var ttfb = (t.responseStart - t.navigationStart) / 1000;
    var pageloadtime = (t.loadEventStart - t.navigationStart) / 1000;
    document.querySelector(selector).innerHTML = "TTFB / Page load time = " + ttfb + " / " + pageloadtime;
};
</script>
<?php

} );
