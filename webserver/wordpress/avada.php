<?php

// Disable Fusion Patcher.
class Fusion_Patcher
{
    public function __construct( $array ) {}

    public function get_patcher_checker()
    {
        return new Fusion_Patcher_Checker();
    }
}
class Fusion_Patcher_Checker
{
    public function get_cache()
    {
        return [];
    }
}

// Disable Fusion Updater.
class Fusion_Updater
{
    public function __construct( $object ) {}
}
