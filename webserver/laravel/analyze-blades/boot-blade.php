<?php

use Illuminate\View\Factory;
use Illuminate\View\Engines\EngineResolver;
use Illuminate\View\FileViewFinder;
use Illuminate\Events\Dispatcher;

$app = app();
/** @var \Illuminate\View\Factory $__env */
$__env = new Factory(
    new EngineResolver(),
    new FileViewFinder($app['files'], $app['config']['view.paths']),
    new Dispatcher()
);
