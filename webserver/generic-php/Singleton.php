<?php

namespace Company\Project;

trait Singleton
{
    private static $instance;

    public static function init()
    {
        if (!self::$instance instanceof self) {
            self::$instance = new self;
        }

        return self::$instance;
    }

    private function __construct() {}
}
