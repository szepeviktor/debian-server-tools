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
     * Hook to the action in the method name.
     *
     * @param string $actionTag
     * @param array $arguments = [
     *     @type string $class
     *     @type int $pritority
     * ]
     */
    public static function __callStatic(string $actionTag, array $arguments): void
    {
        if ($arguments === []) {
            throw new \ArgumentCountError('Class name must be supplied.');
        }

        $class = $arguments[0];

        $constructor = (new ReflectionClass($class))->getConstructor();
        if ($constructor === null) {
            throw new \ErrorException('The class must have a constructor defined.');
        }

        // Hook the constructor.
        add_filter(
            $actionTag,
            function () use ($class) {
                $args = func_get_args();
                new $class(...$args);
            },
            $arguments[1] ?? self::DEFAULT_PRIORITY,
            $constructor->getNumberOfParameters()
        );
    }
}
