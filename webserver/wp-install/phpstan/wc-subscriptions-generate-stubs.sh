#!/bin/bash
#
# Generate WooCommerce Subscriptions stubs.
#

PLUGIN_VERSION="2.5.3"

Get_legacy_files()
{
    # Already in WC
    echo "includes/libraries/"
    # Legacy
    echo "includes/api/legacy/class-wc-rest-subscription-notes-controller.php"
    echo "includes/api/legacy/class-wc-rest-subscriptions-controller.php"
}

# Check plugin
if ! grep -q 'Plugin Name:\s\+WooCommerce Subscriptions' ./woocommerce-subscriptions.php 2>/dev/null; then
    echo "Please extract WooCommerce Subscriptions into the current directory!" 1>&2
    echo "git clone https://github.com/wp-premium/woocommerce-subscriptions.git" 1>&2
    exit 10
fi

# Delete class files
Get_legacy_files | xargs -- rm -v -r

# Generate stubs
if [ ! -x vendor/bin/generate-stubs ]; then
    composer require --no-interaction --update-no-dev --prefer-dist giacocorsiglia/stubs-generator
fi
vendor/bin/generate-stubs --functions --classes --interfaces --traits --out=woocommerce-subscriptions-stubs-${PLUGIN_VERSION}.php ./includes/
