# When to hook in WordPress?

See https://codex.wordpress.org/Plugin_API/Action_Reference

:bulb: Always hook the lastest possible action.

### Earliest time to use `add_filter` and `add_action`

- **Not** when plugin's main file or the themes's `functions.php` file is being loaded!
- Plugins at `plugins_loaded`
- Theme's `functions.php` file is loaded just before `after_setup_theme`
- Generally at `init`

```php
add_action('plugins_loaded', 'myprefix_add_hooks', 10, 0);
```

### Unconditional hooking

- `register_activation_hook()`
- `register_post_type()`

### Based on HTTP request type

- Core request type (entry points and routes),
  see [template hierarchy](https://wphierarchy.com/) and
  [`Toolkit4WP\Is::request()`](https://github.com/szepeviktor/Toolkit4WP/blob/master/src/Is.php#L64-L117)
- Plugin and themes request types (e.g. AMP pages, XML sitemap)

:bulb: Anonymous visitors include ones with JS disabled, robots, attackers and pull CDN.

### Conditional Tags

See https://codex.wordpress.org/Conditional_Tags

- Post type `is_singular($cpt)`
- Page template
- Archives

### On admin pages

- Current admin page, see https://codex.wordpress.org/Plugin_API/Action_Reference/load-(page)
- Logged in users with core roles
- Custom roles

:bulb: `is_admin()` includes `wp_doing_ajax()`!

### In development

- Based on `WP_DEBUG`
- Based on environment name from `WP_ENV`

### HTTP Request variables

GET and POST variables.

:bulb: Best to avoid direct request variable access.

### Login requests

- `register` GET, POST
- `login` GET, POST
- `logout` GET
- `lostpassword` (was `retrievepassword`) GET, POST
- `rp` GET, `resetpass` POST
- `confirm_admin_email` GET _every six months after an admin has logged in_
- `postpass` POST _password protected posts_
- `confirmaction` GET _multisite account activation_
- `WP_Recovery_Mode_Link_Service::LOGIN_ACTION_ENTERED` GET, POST?
