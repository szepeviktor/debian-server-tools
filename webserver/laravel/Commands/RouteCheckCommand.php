<?php

namespace App\Console\Commands;

use Closure;
use Illuminate\Routing\Route;
use Illuminate\Routing\Router;
use Illuminate\Console\Command;
use Symfony\Component\Console\Input\InputOption;

class RouteCheckCommand extends Command
{
    /**
     * The console command name.
     *
     * @var string
     */
    protected $name = 'route:check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check methods of all registered routes';

    /**
     * The router instance.
     *
     * @var \Illuminate\Routing\Router
     */
    protected $router;

    /**
     * An array of all the registered routes.
     *
     * @var \Illuminate\Routing\RouteCollection
     */
    protected $routes;

    /**
     * Create a new route command instance.
     *
     * @param  \Illuminate\Routing\Router  $router
     * @return void
     */
    public function __construct(Router $router)
    {
        parent::__construct();

        $this->router = $router;
        $this->routes = $router->getRoutes();
    }

    /**
     * Execute the console command.
     *
     * @return void
     */
    public function fire()
    {
        if (count($this->routes) == 0) {
            $this->error("Your application doesn't have any routes.");
            exit(10);
        }

        $routes = $this->getRoutes();
        $notFound = array();
        foreach ($routes as $route) {
            $actionParts = explode('@', $route['action']);
            if (count($actionParts) !== 2) {
                $notFound[] = [$route['middleware'], $route['action']];
                continue;
            }

            $className = $actionParts[0];
            if (!class_exists($className)) {
                $notFound[] = [$route['middleware'], $className];
                continue;
            }

            if (!is_callable(array($className, $actionParts[1]))) {
                $notFound[] = [$route['middleware'], $className . '::' . $actionParts[1]];
                continue;
            }
        }

        if (empty($notFound)) {
            $this->info('All route methods do exist.');
            return;
        }

        $this->table(['Middleware', 'Non-existent'], $notFound);
        exit(11);
    }

    /**
     * Compile the routes into a displayable format.
     *
     * @return array
     */
    protected function getRoutes()
    {
        $results = [];

        foreach ($this->routes as $route) {
            $results[] = $this->getRouteInformation($route);
        }

        return array_filter($results);
    }

    /**
     * Get the route information for a given route.
     *
     * @param  \Illuminate\Routing\Route  $route
     * @return array
     */
    protected function getRouteInformation(Route $route)
    {
        return [
            'host'   => $route->domain(),
            'method' => implode('|', $route->methods()),
            'uri'    => $route->uri(),
            'name'   => $route->getName(),
            'action' => $route->getActionName(),
            'middleware' => $this->getMiddleware($route),
        ];
    }

    /**
     * Get before filters.
     *
     * @param  \Illuminate\Routing\Route  $route
     * @return string
     */
    protected function getMiddleware($route)
    {
        return collect($route->gatherMiddleware())->map(function ($middleware) {
            return $middleware instanceof Closure ? 'Closure' : $middleware;
        })->implode(',');
    }
}
