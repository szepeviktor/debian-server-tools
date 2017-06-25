# WordPress performance

How to achieve high performance in WordPress?

| Item                          | Tool                               | Speedup                       |
| ----------------------------- | ---------------------------------- | ----------------------------- |
| Infrastructure                | CPU, disk, DNS, web server, PHP    | Overall performance           |
| Server-side functionality     | backup, plugins replicating WP-CLI | **Degrades** performance      |
| In-memory object cache        | Redis, Memcached, APCu             | options, post, post meta etc. |
| Cache-aware theme and plugins | transients or object cache         | HTML content                  |
| Translation cache             | `tiny-translation-cache`           | .po and .mo file parsing      |
| Navigation menu cache         | `tiny-nav-menu-cache`              | `wp_nav_menu()`               |
| Post content cache            | `tiny-cache`                       | `the_content()`               |
| Widget output cache           | `widget-output-cache` plugin       | HTML content                  |
