<?php declare(strict_types=1);

namespace WordPress;

use ReflectionClass;
use function add_filter;

/**
 * Hook a class constructor on to a specific action.
 *
 * Example call with priority zero.
 *
 *     HookConstructorTo::init(MyClass::class, 0);
 */
class HookConstructorTo
{
    protected const DEFAULT_PRIORITY = 10;

    /**
     * Hook to any action name.
     *
     * @param string $actionTag
     * @param array $arguments = [
     *     @type string $class
     *     @type string $pritority
     * ]
     */
    public static function __callStatic(string $actionTag, array $arguments): void
    {
        $argCount = count($arguments);
        if ($argCount < 1) {
            throw new \ArgumentCountError('Please provide a class name.');
        }

        $class = $arguments[0];

        $constructor = (new ReflectionClass($class))->getConstructor();
        if ($constructor === null) {
            throw new \ErrorException('Please provide a class with constructor.');
        }

        // Hook the constructor.
        add_filter(
            $actionTag,
            function () use ($class) {
                $args = func_get_args();
                new $class(...$args);
            },
            ($argCount >= 2) ? $arguments[1] : self::DEFAULT_PRIORITY,
            $constructor->getNumberOfParameters()
        );
    }
}
