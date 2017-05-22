<script>
// Display page load time.
// https://www.stevesouders.com/blog/2014/08/21/resource-timing-practical-tips/
window.onload = function () {
    "use strict";
    var selector = ".welcome-msg",
        t = window.performance.timing,
        ttfb = (t.responseStart - t.navigationStart) / 1000,
        pageloadtime = (t.loadEventStart - t.navigationStart) / 1000;
    document.querySelector(selector).innerHTML = "TTFB / Page load time = " + ttfb + " / " + pageloadtime;
};
</script>
