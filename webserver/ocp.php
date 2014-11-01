<?php
/*
Name: OCP - Opcache Control Panel   (aka Zend Optimizer+ Control Panel for PHP)
Author: _ck_   (with contributions by GK, stasilok, n1xim, pennedav, kabel)
Version: 0.2.0
Gist URL: https://gist.github.com/kabel/d12c35bde74814e45c14

Free for any kind of use or modification, I am not responsible for anything, please share your improvements

* revision history
0.2.0  0000-00-00  Updated page layout/styles and restructure code to be more MVC-like (kabel)
                   implemented HTTP Basic authentication (pennedav)
                   changed scaling of "hits" to base 10 (n1xim)
0.1.6  2013-04-12  moved meta to footer so graphs can be higher and reduce clutter
0.1.5  2013-04-12  added graphs to visualize cache state, please report any browser/style bugs
0.1.4  2013-04-09  added "recheck" to update files when using large revalidate_freq (or validate_timestamps=Off)
0.1.3  2013-03-30  show host and php version, can bookmark with hashtag ie. #statistics - needs new layout asap
0.1.2  2013-03-25  show optimization levels, number formatting, support for start_time in 7.0.2
0.1.1  2013-03-18  today Zend completely renamed Optimizer+ to OPcache, adjusted OCP to keep working
0.1.0  2013-03-17  added group/sort indicators, replaced "accelerator_" functions with "opcache_"
0.0.6  2013-03-16  transition support as Zend renames product and functions for PHP 5.5 (stasilok)
0.0.5  2013-03-10  added refresh button (GK)
0.0.4  2013-02-18  added file grouping and sorting (click on headers) - code needs cleanup but gets the job done
0.0.2  2013-02-14  first public release

* known problems/limitations:
Unlike APC, the Zend OPcache API
 - cannot determine when a file was put into the cache
 - cannot change settings on the fly
*/

namespace {

$config = array(
    // 'auth' => array(
    //     'enabled' => true,
    //     'username' => 'ocp',
    //     'password' => 'password',
    // ),
    // 'test' => true,
);

$app = new OCP\App($config);
$app->run();

}

namespace OCP {

class Opcache 
{
    protected $extension = '';
    protected $iniPrefix = '';
    protected $functionPrefix = '';

    protected $status;

    protected $isTest = false;

    public function __construct()
    {
        foreach (array('zend opcache', 'zend optimizer+') as $name) {
            if (extension_loaded($name)) {
                $this->extension = $name;

                switch ($name) {
                    case 'zend opcache':
                        $this->functionPrefix = 'opcache_';
                        $this->iniPrefix = 'opcache.';
                        break;
                    case 'zend optimizer+':
                        $this->functionPrefix = 'accelerator_';
                        $this->iniPrefix = 'zend_optimizerplus.';
                        break;
                }
                break;
            }
        }
    }
    
    public function setIsTest($value)
    {
        $this->isTest = (bool)$value;
        return $this;
    }
    
    public function getIniPrefix()
    {
        return $this->iniPrefix;
    }
    
    public function getFunctionPrefix()
    {
        return $this->functionPrefix;
    }
    
    public function getExtension()
    {
        return $this->extension;
    }

    public function isAvailable()
    {
        return !empty($this->extension);
    }

    public function reset()
    {
        if ($this->isTest) {
            return true;
        }

        return call_user_func($this->functionPrefix . 'reset');
    }

    public function canRecheck()
    {
        return function_exists($this->functionPrefix . 'invalidate');
    }

    public function invalidate($file)
    {
        if ($this->isTest) {
            return true;
        }

        return call_user_func($this->functionPrefix . 'invalidate', $file);
    }

    public function invalidatePath($path)
    {
        $files = array_keys($this->getCachedScripts($path));
        foreach ($files as $file) {
            $this->invalidate($file);
        }
    }

    public function getStatus()
    {
        if (empty($this->status)) {
            $this->status = call_user_func($this->functionPrefix . 'get_status');
        }

        return $this->status;
    }
    
    public function getStatistics()
    {
        $status = $this->getStatus();
        return $status[$this->functionPrefix . 'statistics'];
    }

    public function getCachedScripts($path, $asTree = true)
    {
        $status = $this->getStatus();
        if (!isset($status['scripts'])) {
            return array();
        }

        $files = $status['scripts'];
        $result = array();

        if (!empty($path)) {
            foreach ($files as $file => $info) {
                if (strpos($file, $path) === 0) {
                    $result[$file] = $info;
                }
            }

            $files = $result;
            $result = array();
        }

        if (!$asTree) {
            return $files;
        }

        foreach ($files as $file => $info) {
            $dirs = explode(DIRECTORY_SEPARATOR, rtrim($file, DIRECTORY_SEPARATOR));
            $file = array_pop($dirs);

            $resultPos =& $result;
            $fullPath = '';

            foreach ($dirs as $dir) {
                $fullPath .= $dir . DIRECTORY_SEPARATOR;

                if (empty($dir)) {
                    continue;
                }

                if (!isset($resultPos[$dir])) {
                    $resultPos[$dir] = array(
                        'full_path' => $fullPath,
                        'hits' => $info['hits'],
                        'memory_consumption' => $info['memory_consumption'],
                        'last_used' => $info['last_used'],
                        'last_used_timestamp' => $info['last_used_timestamp'],
                        'timestamp' => $info['timestamp'],
                        'directory' => true,
                        'children' => array(),
                    );
                } else {
                    $resultPos[$dir]['hits'] += $info['hits'];
                    $resultPos[$dir]['memory_consumption'] += $info['memory_consumption'];
                    if ($resultPos[$dir]['last_used_timestamp'] < $info['last_used_timestamp']) {
                        $resultPos[$dir]['last_used_timestamp'] = $info['last_used_timestamp'];
                        $resultPos[$dir]['last_used'] = $info['last_used'];
                    }
                    if (empty($resultPos[$dir]['timestamp']) || !empty($info['timestamp']) && $resultPos[$dir]['timestamp'] > $info['timestamp']) {
                        $resultPos[$dir]['timestamp'] = $info['timestamp'];
                    }
                }

                $tempRef =& $resultPos[$dir]['children'];
                unset($resultPos);
                $resultPos =& $tempRef;
                unset($tempRef);
            }

            $resultPos[$file] = $info;
        }

        // return the requested path
        if (!empty($path)) {
            $dirs = explode(DIRECTORY_SEPARATOR, rtrim($path, DIRECTORY_SEPARATOR));

            foreach ($dirs as $dir) {
                if (empty($dir)) {
                    continue;
                }

                if (!isset($result[$dir])) {
                    $result = array();
                    break;
                } else {
                    $result = $result[$dir]['children'];
                }
            }
        }

        return $result;
    }

    public function getConfiguration()
    {
        if (function_exists($this->functionPrefix . 'get_configuration')) {
            return call_user_func($this->functionPrefix . 'get_configuration');
        }

        return false;
    }
    
    public function getAllIni()
    {
        return ini_get_all($this->extension);
    }
    
    public function getFunctions()
    {
        return get_extension_funcs($this->extension);
    }
}

class Url
{
    public function getUrl($urlParts = array(), $absolute = false)
    {
        $url = '';
    
        if (empty($urlParts['path'])) {
            $urlParts['path'] = $_SERVER['PHP_SELF'];
        }
    
        if (!empty($urlParts['query'])) {
            if (is_array($urlParts['query'])) {
                $urlParts['query'] = http_build_query($urlParts['query']);
            }
        }
    
        if ($absolute) {
            if (!empty($_SERVER['HTTPS'])) {
                $urlParts['scheme'] = 'https';
            } else {
                $urlParts['scheme'] = 'http';
            }
    
            if (!empty($_SERVER['HTTP_HOST'])) {
                $hostParts = explode(':', $_SERVER['HTTP_HOST'], 2);
                $urlParts['host'] = $hostParts[0];
                if (isset($hostParts[1])) {
                    $urlParts['port'] = $hostParts[1];
                }
            } else {
                $urlParts['host'] = $_SERVER['SERVER_ADDR'];
                $serverPort = $_SERVER['SERVER_PORT'];
                if (($urlParts['scheme'] === 'http' && $serverPort != 80) || ($urlParts['scheme' === 'https' && $serverPort != 443])) {
                    $urlParts['port'] = $serverPort;
                }
            }
    
            $url = $urlParts['scheme'] . '://' . $urlParts['host'];
        }
    
        $url .= $urlParts['path'];
    
        if (!empty($urlParts['query'])) {
            $url .= '?' . $urlParts['query'];
        }
    
        if (!empty($urlParts['fragment'])) {
            $url .= '#' . $urlParts['fragment'];
        }
    
        return $url;
    }
}

abstract class View
{
    protected $time = null;
    
    protected $viewParams = array();
    
    protected $urlModel = null;
    
    public function getPathDirs($path)
    {
        return explode(DIRECTORY_SEPARATOR, rtrim($path, DIRECTORY_SEPARATOR));
    }
    
    public function getParentDirs($path)
    {
        $dirs = $this->getPathDirs($path);
        
        
    }

    public function getDisplayPercent($value, $total)
    {
        if (!$total) {
            return '';
        }

        $percent = round($value / $total * 100, 1);

        if ($percent < 1) {
            return '';
        }

        return $percent . '%';
    }

    public function getFormattedValue($value, $base2 = false, $precision = 0)
    {
        $suffix = '';

        if ($base2) {
            $exp = floor(log($value, 2));
            
            if ($exp >= 20) {
                $exp = 20;
                $suffix = ' MiB';
            } elseif ($exp >= 13) {
                $exp = 10;
                $suffix = ' KiB';
            } else {
                $exp = 0;
            }

            $value = round($value / pow(2, $exp), $precision) . $suffix;
        } else {
            $exp = floor(log($value, 10));

            if ($exp >= 6) {
                $exp = 6;
                $suffix = ' M';
            } elseif ($exp >= 4) {
                $exp = 3;
                $suffix = ' k';
            } else {
                $exp = 0;
            }

            $value = round($value / pow(10, $exp), $precision) . $suffix;
        }
        
        return $value;
    }

    public function escapeHtml($html)
    {
        return htmlspecialchars($html, ENT_COMPAT, 'UTF-8');
    }

    public function getTimeSince($since, $short = false, $limit = false)
    {
        if ($this->time === null) {
            $this->time = time();
        }
        
        $ret = array();
        $secs = $this->time - $since;

        $bit = array(
                'year'      => $secs / 31556926 % 12,
                'week'      => $secs / 604800 % 52,
                'day'       => $secs / 86400 % 7,
                'hour'      => $secs / 3600 % 24,
                'minute'    => $secs / 60 % 60,
                'second'    => $secs % 60,
        );
             
        foreach ($bit as $k => $v){
            if ($short) {
                $k = $k[0];
            }

            if ($v) {
                if ($short) {
                    $vk = $v . $k;
                } else {
                    $vk = $v . ' ' . $k . ($v > 1 ? 's' : '');
                }

                $ret[] = $vk;
            }
        }

        if ($limit) {
            $ret = array_slice($ret, 0, $limit);
        }

        if (!$short && count($ret) > 1) {
            array_splice($ret, count($ret) - 1, 0, 'and');
        }
     
        return implode(' ', $ret);
    }
    
    public function getUrl($urlParts = array(), $absolute = false)
    {
        if ($this->urlModel === null) {
            $this->urlModel = new Url();
        }
        
        return $this->urlModel->getUrl($urlParts, $absolute);
    }
    
    public function getViewUrl($addons = array())
    {
        $params = array_merge($this->viewParams, $addons);
        return $this->getUrl(array('query' => $params));
    }
}

class Graphs extends View
{
    protected $opcache;

    public function __construct(Opcache $opcache)
    {
        $this->opcache = $opcache;
    }

    public function __toString()
    {
        $config = $this->opcache->getConfiguration();
        $status = $this->opcache->getStatus();
        $stats = $this->opcache->getStatistics();
        
        $labelColors = array(
            'free' => 'green',
            'used' => 'brown',
            'wasted' => 'red',
            'scripts' => 'brown',
            'hits' => 'green',
            'misses' => 'brown',
            'blacklist' => 'red',
            'manual' => 'green',
            'keys' => 'brown',
            'memory' => 'red',
        );
        
        $graphs = array(
            'memory' => array(
                '1free' => $status['memory_usage']['free_memory'],
                '2used' => $status['memory_usage']['used_memory'],
                '3wasted' => $status['memory_usage']['wasted_memory'],
            ),
            'keys' => array(
                '0total' => isset($stats['max_cached_keys']) ? $stats['max_cached_keys'] : $stats['max_cached_scripts'],
                '2scripts' => $stats['num_cached_scripts'],
            ),
            'hits' => array(
                '1hits' => $stats['hits'],
                '2misses' => $stats['misses'],
                '3blacklist' => $stats['blacklist_misses'],
            ),
        );
        
        $graphs['hits']['0total'] = array_sum($graphs['hits']);
        
        if (!empty($config)) {
            $graphs['memory']['0total'] = $config['directives'][$this->opcache->getIniPrefix() . 'memory_consumption'];
        } else {
            $graphs['memory']['0total'] = array_sum($graphs['memory']);
        }
        
        if (isset($stats['num_cached_keys'])) {
            $graphs['keys']['1free'] = $graphs['keys']['0total'] - $stats['num_cached_keys'];
            $graphs['keys']['3wasted'] = $stats['num_cached_keys'] - $graphs['keys']['2scripts'];
        } else {
            $graphs['keys']['1free'] = $graphs['keys']['0total'] - $graphs['keys']['2scripts'];
        }
        
        if (isset($stats['manual_restarts'])) {
            $graphs['restarts'] = array(
                '1manual' => $stats['manual_restarts'],
                '2keys' => $stats['hash_restarts'],
                '3memory' => $stats['oom_restarts'],
            );
        
            $graphs['restarts']['0total'] = array_sum($graphs['restarts']);
        }
        
        foreach ($graphs as $title => $graph) {
            ksort($graph);
            $sortedGraph = array();
            foreach ($graph as $label => $value) {
                if (is_numeric($label[0])) {
                    $label = substr($label, 1);
                }
                $sortedGraph[$label] = $value;
            }
            $graphs[$title] = $sortedGraph;
            unset($sortedGraph);
        }
        
        ob_start(); ?>
<section class="clearfix graph-set">
<?php foreach ($graphs as $title => $graph): ?>
<div class="graph">
    <h2 class="title"><?php echo ucwords($title) ?></h2>
    <table>
        <tr>
            <td class="total" rowspan="<?php echo count($graph) - 1 ?>">
                <?php $fValue = $this->getFormattedValue($graph['total'], $title == 'memory'); ?>
                <span<?php if ($graph['total'] != $fValue): ?> title="<?php echo $graph['total'] ?>"<?php endif; ?>><?php echo $fValue ?></span>
            </td>
        <?php $i = 0; ?>
        <?php foreach ($graph as $label => $value): ?>
        <?php if ($label == 'total') { continue; } ?>
            <?php if ($i != 0): ?>
        <tr>
            <?php endif; ?>
            <td class="actual">
                <?php $fValue = $this->getFormattedValue($value, $title == 'memory'); ?>
                <span<?php if ($fValue != $value): ?> title="<?php echo $value ?>"<?php endif; ?>><?php echo $fValue ?>
                </span>
            </td>
            <?php $percent = $this->getDisplayPercent($value, $graph['total']); ?>
            <td class="bar <?php echo  $labelColors[$label] ?>"<?php if ($percent): ?> style="height: <?php echo $percent ?>"<?php endif; ?>><?php echo $percent ?></td>
            <td><?php echo $label ?></td>
            <?php ++$i; ?>
        </tr>
        <?php endforeach; ?>
    </table>
</div>
<?php endforeach; ?>
</section>
<?php
        return ob_get_clean();
    }
}

class Info extends View
{
    protected $opcache;
    
    public function __construct(Opcache $opcache)
    {
        $this->opcache = $opcache;
    }
    
    public function __toString()
    {
        $config = $this->opcache->getConfiguration();
        $status = $this->opcache->getStatus();
        $stats = $this->opcache->getStatistics();
        
        $funcPrefix = $this->opcache->getFunctionPrefix();
        $iniPrefix = $this->opcache->getIniPrefix();
        
        ob_start(); ?>
<section>
    <h2 class="title">General</h2>
    <div class="table-overflow">
    <table class="doctable pivot">
        <caption>General Host Information</caption>
        <col style="width: 50%" />
        <col />
        <tbody>
            <tr>
                <th>Host</th>
                <td><?php
                foreach (array('SERVER_NAME', 'HTTP_HOST', 'SERVER_ADDR') as $hostVar) {
                    if (!empty($_SERVER[$hostVar])) {
                        echo $this->escapeHtml($_SERVER[$hostVar]);
                        break;
                    }
                }
                ?></td>
            </tr>
            <tr>
                <th>PHP Version</th>
                <td><?php
                foreach (array('PHP_VERSION', 'PHP_SAPI', 'PHP_OS') as $versionConst) {
                    if (constant($versionConst)) {
                        echo $this->escapeHtml(constant($versionConst) . ' ');
                    }
                }
                ?></td>
            </tr>
            <?php if ($config): ?>
            <tr>
                <th>OPcache Version</th>
                <td><?php echo $this->escapeHtml($config['version'][$funcPrefix . 'product_name'] . ' ' . $config['version']['version']) ?></td>
            </tr>
            <tr>
                <th>Opcode Caching</th>
                <td><?php echo $config['directives'][$iniPrefix . 'enable'] ? 'Up and Running' : 'Disabled' ?></td>
            </tr>
            <tr>
                <th>Optimization</th>
                <td><?php echo ($config['directives'][$iniPrefix . 'enable'] && $config['directives'][$iniPrefix . 'optimization_level']) ? 'Enabled' : 'Disabled' ?></td>
            </tr>
        <?php endif; ?>

        <tr>
            <th>Uptime</th>
            <td><?php
            foreach (array('last_restart_time', 'start_time') as $uptimeVar) {
                if (!empty($stats[$uptimeVar])) {
                    echo $this->getTimeSince($stats[$uptimeVar]);
                    break;
                }
            }
            ?></td>
        </tr>
        </tbody>
    </table>
    </div>
</section>
<?php
        return ob_get_clean();
    }
}

class Stats extends View
{
    protected $opcache;
    
    public function __construct(Opcache $opcache)
    {
        $this->opcache = $opcache;
    }
    
    public function __toString()
    {
        $config = $this->opcache->getConfiguration();
        $status = $this->opcache->getStatus();
        $stats = $this->opcache->getStatistics();
        
        ob_start(); ?>
<section>
    <h2 id="memory" class="title">Memory</h2>
    <div class="table-overflow">
    <table class="doctable pivot">
        <caption>OPcache Memory Utilization</caption>
        <col style="width: 50%" />
        <col />
        <tbody>
            <tr>
                <th>Cache Full</th>
                <td><?php echo $status['cache_full'] ? 'Yes' : 'No' ?>
            </tr>
            <?php foreach ($status['memory_usage'] as $title => $value): ?>
            <tr>
                <th><?php echo ucwords(str_replace('_', ' ', $title)) ?></th>
                <td><?php
                if (is_int($value)) {
                    echo $this->getFormattedValue($value, true, 1);
                } else {
                    echo round($value, 1);
                }
                ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
    </div>

    <?php if (isset($status['interned_strings_usage'])): ?>
    <div class="table-overflow">
    <table class="doctable pivot">
        <caption>OPcache Interned Strings Utilization</caption>
        <col style="width: 50%" />
        <col />
        <tbody>
            <?php foreach ($status['interned_strings_usage'] as $title => $value): ?>
            <tr>
                <th><?php echo ucwords(str_replace('_', ' ', $title)) ?></th>
                <td>
                    <?php
                    if (strpos($value, 'number') === false) {
                        $fValue = $this->getFormattedValue($value, true, 1);
                    } else {
                        $fValue = round($value, 1);
                    }
                    ?>
                    <span<?php if ($fValue != $value): ?> title="<?php echo $value ?>"<?php endif; ?>><?php echo $fValue ?></span>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
    </div>
    <?php endif; ?>

    <h2 id="statistics" class="title">Statistics</h2>
    <div class="table-overflow">
    <table class="doctable pivot">
        <caption>Raw OPcache Statistics Data</caption>
        <col style="width: 50%" />
        <col />
        <tbody>
        <?php foreach ($stats as $title => $value): ?>
            <tr>
                <th><?php echo $this->escapeHtml($title) ?></th>
                <td><?php echo $this->escapeHtml($value) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    </div>
</section>
<?php
        return ob_get_clean();
    }
}

class Config extends View
{
    protected $opcache;
    
    public function __construct(Opcache $opcache)
    {
        $this->opcache = $opcache;
    }
    
    public function __toString()
    {
        $config = $this->opcache->getConfiguration();
        $ini = $this->opcache->getAllIni();
        $iniPrefix = $this->opcache->getIniPrefix();
        $directives = array();
        
        if ($config) {
            $directives = $config['directives'];
            $opLevel = $directives[$iniPrefix . 'optimization_level'];
        } else {
            $opLevel = intval($ini[$iniPrefix . 'optimization_level']['local_value'], 0);
        }
        
        $functions = $this->opcache->getFunctions();
        
        ob_start(); ?>
<section>
    <?php if ($config && !empty($config['blacklist'])): ?>
    <h2 id="blacklist" class="title">Blacklist Entries</h2>
    <ul>
    <?php foreach ($config['blacklist'] as $entry): ?>
        <li><?php echo $this->escapeHtml($entry) ?></li>
    <?php endforeach; ?>
    <ul>
    <?php endif; ?>

    <h2 id="runtime" class="title">Runtime Configuration</h2>
    <div class="table-overflow">
    <table class="doctable">
        <thead>
            <tr>
                <th>Name</th>
                <th>Local Value</th>
                <th>Master Value</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($ini as $directive => $info): ?>
            <tr>
                <?php 
                $directiveFragment = str_replace('_', '-', $directive);
                if ($iniPrefix !== 'opcache.') {
                    $directiveFragment = str_replace($iniPrefix, 'opcache.', $directiveFragment);
                }
                ?>
                <td><a href="http://docs.php.net/manual/en/opcache.configuration.php#ini.<?php echo $directiveFragment ?>"><?php echo $this->escapeHtml($directive) ?></a></td>
                <td><?php echo $this->escapeHtml($info['local_value']) ?></td>
                <td><?php echo $this->escapeHtml($info['global_value']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    </div>

    <h2 id="functions" class="title">OPcache Functions</h2>
    <ul>
    <?php foreach ($functions as $func): ?>
        <li><a href="http://docs.php.net/manual/en/function.<?php echo str_replace('_', '-', $func) ?>.php"><?php echo $func ?></a></li>
    <?php endforeach; ?>
    </ul>

    <h2 id="optimization" class="title">Optimization Levels</h2>
    <div class="table-overflow">
    <table class="doctable">
        <thead>
            <tr>
                <th>Step</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr<?php if (!($opLevel & 1)): ?> class="disabled"<?php endif; ?>>
                <td>1</td>
                <td>
                    <ul>
                        <li><a href="http://wikipedia.org/wiki/Common_subexpression_elimination"><abbr title="constants subexpressions elimination">CSE</abbr></a></li>
                        <li>Optimize series of <a href="http://docs.php.net/manual/en/internals2.opcodes.add-char.php">ADD_CHAR</a>/<a href="http://docs.php.net/manual/en/internals2.opcodes.add-string.php">ADD_STRING</a></li>
                        <li>Convert <a href="http://docs.php.net/manual/en/internals2.opcodes.cast.php">CAST</a>(IS_BOOL,x) into <a href="http://docs.php.net/manual/en/internals2.opcodes.bool.php">BOOL</a>(x)
                        <li>Convert <a href="http://docs.php.net/manual/en/internals2.opcodes.init-fcall-by-name.php">INIT_FCALL_BY_NAME</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.do-fcall-by-name.php">DO_FCALL_BY_NAME</a> into <a href="http://docs.php.net/manual/en/internals2.opcodes.do-fcall.php">DO_FCALL</a></li>
                    </ul>
                </td>
            </tr>
            <tr<?php if (!($opLevel & 1 << 1)): ?> class="disabled"<?php endif; ?>>
                <td>2</td>
                <td>
                    <ul>
                        <li>Convert non-numeric constants to numeric constants in numeric operators</li>
                        <li>Optimize constant conditional jumps (<a href="http://docs.php.net/manual/en/internals2.opcodes.jmpz-ex.php">JMPZ_EX</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpnz-ex.php">JPMNZ_EX</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpz.php">JMPZ</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpnz.php">JMPNZ</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpznz.php">JMPZNZ</a>)</li>
                        <li>Optimize static <a href="http://docs.php.net/manual/en/internals2.opcodes.brk.php">BRK</a>s and <a href="http://docs.php.net/manual/en/internals2.opcodes.cont.php">CONT</a>s</li>
                    </ul>
                </td>
            </tr>
            <tr<?php if (!($opLevel & 1 << 2)): ?> class="disabled"<?php endif; ?>>
                <td>3</td>
                <td>
                    <ul>
                        <li>Convert <code>$a = $a + expr</code> into <code>$a += expr</code></li>
                        <li>Convert <code>$a++</code> into </code>++$a</code> where possible</li>
                        <li>Optimize series of jumps (<a href="http://docs.php.net/manual/en/internals2.opcodes.jmp.php">JMP</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpz-ex.php">JMPZ_EX</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpnz-ex.php">JPMNZ_EX</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpz.php">JMPZ</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpnz.php">JMPNZ</a>, <a href="http://docs.php.net/manual/en/internals2.opcodes.jmpznz.php">JMPZNZ</a>)</li>
                    </ul>
                </td>
            </tr>
            <tr class="disabled">
                <td>4</td>
                <td>PRINT and ECHO optimization (<a href="https://github.com/zend-dev/ZendOptimizerPlus/issues/73">defunct</a>)</td>
            </tr>
            <tr<?php if (!($opLevel & 1)): ?> class="disabled"<?php endif; ?>>
                <td>5</td>
                <td><a href="http://en.wikipedia.org/wiki/Control_flow_graph"><abbr title="control flow graph">CFG</abbr></a> optimization</td>
            </tr>
            <tr<?php if (!($opLevel & 1)): ?> class="disabled"<?php endif; ?>>
                <td>9</td>
                <td><a href="http://en.wikipedia.org/wiki/Register_allocation">Register allocation</a> optimization (allows re-usage of temporary variables)</td>
            </tr>
            <tr<?php if (!($opLevel & 1)): ?> class="disabled"<?php endif; ?>>
                <td>10</td>
                <td>Remove <a href="http://docs.php.net/manual/en/internals2.opcodes.nop.php">NOP</a>s</td>
            </tr>
        </tbody>
    </table>
    </div>

</section>
<?php
        return ob_get_clean();
    }
}

class Files extends View
{
    protected $opcache;
    
    protected $treeView;
    
    public function __construct(Opcache $opcache, $viewParams, $treeView = true)
    {
        $this->opcache = $opcache;
        $this->viewParams = $viewParams;
        $this->treeView = $treeView;
    }
    
    protected function getParentPath($path)
    {
        $dirs = $this->getPathDirs($path);
        $parentPath = '';
        
        if (empty($dirs[0])) {
            $parentPath = DIRECTORY_SEPARATOR;
            array_shift($dirs);
        }
        
        $dirDepth = count($dirs);
        if ($dirDepth) {
            if ($dirDepth > 1) {
                array_pop($dirs);
                return $parentPath . implode(DIRECTORY_SEPARATOR, $dirs) . DIRECTORY_SEPARATOR;
            } else {
                return null;
            }
        }
        
        return false;
    }
    
    protected function getPathHtml($path)
    {
        $dirs = $this->getPathDirs($path);
        $parentPath = '';
        
        if (!empty($dirs[0])) {
            $root = 'Computer';
        } else {
            $root = $parentPath = DIRECTORY_SEPARATOR;
            array_shift($dirs);
        }
        
        $count = count($dirs);
        
        if (!$count) {
            return '';
        }
        
        ob_start(); ?>
<caption>
    <span>Current Path:</span>
    <span><a href="<?php echo $this->getViewUrl(array('p' => null)) ?>"><?php echo $root ?></a></span><?php foreach ($dirs as $i => $dir): ?><?php $parentPath .= $dir . DIRECTORY_SEPARATOR; ?><span><?php if ($i < ($count - 1)): ?><a href="<?php echo $this->getViewUrl(array('p' => $parentPath)) ?>"><?php endif; ?><?php echo $this->escapeHtml($dir) ?><?php if ($i < ($count - 1)): ?></a><?php endif; ?></span><span><?php echo DIRECTORY_SEPARATOR ?></span><?php endforeach; ?>
</caption>
<?php
        return ob_get_clean();
    }
    
    public function __toString()
    {
        $path = '';
        $parent = false;
        
        if (isset($this->viewParams['p'])) {
            $path = $this->viewParams['p'];
            $parent = $this->getParentPath($path);
        }
        
        $files = $this->opcache->getCachedScripts($path, $this->treeView);
        
        ob_start(); ?>
<section>
    <p>
        <a href="<?php echo $this->getViewUrl(array('md' => null)) ?>" <?php echo $this->treeView ? ' class="active"' : '' ?>>Tree View</a> /
        <a href="<?php echo $this->getViewUrl(array('md' => 'list', 'p' => null)) ?>"<?php echo $this->treeView ? '' : ' class="active"' ?>>List View</a>
    </p>
    <h2 class="title">Cached Scripts</h2>
    <div class="table-overflow">
    <table id="files" class="doctable">
        <?php echo $this->getPathHtml($path) ?>
        <thead>
            <tr>
                <th data-index="path">Path</th>
                <th data-index="size">Size</th>
                <th data-index="hits">Hits</th>
                <th data-index="lastused">Last Used</th>
                <th data-index="timestamp">Created</th>
            </tr>
        </thead>
        <tbody>
        <?php if (!empty($files)): ?>
            <?php if ($parent !== false): ?>
            <tr>
                <td><a title="Parent directory" href="<?php echo $this->getViewUrl(array('p' => $parent)) ?>">..</a></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
            </tr>
            <?php endif; ?>
        <?php foreach ($files as $file => $info): ?>
            <tr data-path="<?php echo $this->escapeHtml($info['full_path']) ?>" data-size="<?php echo $info['memory_consumption'] ?>" data-hits="<?php echo $info['hits'] ?>" data-lastused="<?php echo $info['last_used_timestamp'] ?>" data-timestamp="<?php echo $info['timestamp'] ?>">
                <td>
                    <?php if ($this->opcache->canRecheck()): ?>
                    <form method="post">
                        <input type="hidden" name="rp" value="<?php echo $this->escapeHtml($info['full_path']) ?>" />
                        <button type="submit" name="action" value="RECHECK" title="Recheck">x</button>
                    </form>
                    <?php endif; ?>
                    <?php
                    $isDir = $this->treeView && isset($info['directory']) && $info['directory'];
                    if ($isDir):
                    ?>
                    <a href="<?php echo $this->getViewUrl(array('p' => $info['full_path'])) ?>">
                    <?php endif; ?>
                    <?php echo $this->escapeHtml($file) ?>
                    <?php if($isDir): ?>
                    </a>
                    <?php endif; ?>
                </td>
                <td><?php echo $this->getFormattedValue($info['memory_consumption'], true) ?></td>
                <td><?php echo number_format($info['hits']) ?></td>
                <td><?php
                    $ago = $this->getTimeSince($info['last_used_timestamp'], true);
                    if ($ago) {
                        echo $ago;
                    } else {
                        echo 'now';
                    }
                ?></td>
                <td><?php echo !empty($info['timestamp']) ? $this->getTimeSince($info['timestamp'], true) : '' ?></td>
            </tr>
        <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
    </div>
    <script>
    ;(function(window) {
        "use strict";

        var DS = <?php echo json_encode(DIRECTORY_SEPARATOR) ?>,
            scripts = <?php echo json_encode($this->opcache->getCachedScripts('', true)) ?>,
            rootUrl = <?php echo json_encode($this->getViewUrl(array('p' => null))) ?>,
            scriptTable = document.getElementById('files'),
            orderActive = null,
            orderReverse = 0;

        function getDirs(path) {
            return path.replace(new RegExp(DS + '$'), '').split(DS);
        };

        function getParentDir(path) {
            var dirs = getDirs(path), parentPrefix = '';

            if (!dirs[0]) {
                dirs.shift();
                parentPrefix = DS;
            }

            if (dirs.length) {
                if (dirs.length > 1) {
                    dirs.pop();
                    return parentPrefix + dirs.join(DS) + DS;
                } else {
                    return null;
                }
            }

            return undefined;
        }

        function formatSize(size) {
            var exp = Math.floor(Math.log(size) / Math.LN2),
                suffix = '',
                result;

            if (exp >= 20) {
                exp = 20;
                suffix = ' MiB';
            } else if (exp >= 13) {
                exp = 10;
                suffix = ' KiB';
            } else {
                exp = 0;
            }

            return Math.round(size / Math.pow(2, exp)) + suffix;
        };

        function formatHits(hits) {
            return hits.toLocaleString();
        };

        function formatTime(timestamp) {
            var now = +(new Date) / 1000,
                secs = now - timestamp,
                i, ret = [],
                bit = {
                    'y' : Math.floor(secs / 31556926 % 12),
                    'w' : Math.floor(secs / 604800 % 52),
                    'd' : Math.floor(secs / 86400 % 7),
                    'h' : Math.floor(secs / 3600 % 24),
                    'm' : Math.floor(secs / 60 % 60),
                    's' : Math.floor(secs % 60),
            };

            if (!timestamp) {
                return '';
            }
                 
            for (i in bit){
                if (bit[i]) {
                    ret.push(Math.floor(bit[i]) + i);
                }
            }
         
            return ret.join(' ');
        };

        function renderCurrentPath(parent, path) {
            var dirs = getDirs(path),
                parentPath = '',
                root, i, span, spanChild;

            if (dirs[0] !== '') {
                root = 'Computer';
            } else {
                root = parentPath = DS;
                dirs.shift();
            }

            if (!dirs.length) {
                return;
            }

            span = document.createElement('span');
            spanChild = document.createTextNode("Current Path: ");
            span.appendChild(spanChild);
            parent.appendChild(span);

            span = document.createElement('span');
            spanChild = document.createElement('a');
            spanChild.href = rootUrl;
            spanChild.appendChild(document.createTextNode(root));
            span.appendChild(spanChild);
            parent.appendChild(span);

            for (i = 0; i < dirs.length; ++i) {
                parentPath += dirs[i] + DS;
                span = document.createElement('span');
                if (i < dirs.length - 1) {
                    spanChild = document.createElement('a');
                    spanChild.href = rootUrl + '&p=' + encodeURIComponent(parentPath);
                    spanChild.appendChild(document.createTextNode(dirs[i]));
                } else {
                    spanChild = document.createTextNode(dirs[i]);
                }

                span.appendChild(spanChild);
                parent.appendChild(span);

                span = document.createElement('span');
                span.appendChild(document.createTextNode(DS));
                parent.appendChild(span);
            }
        };

        function renderScripts(scripts, parentPath) {
            var i, row, cell, script, form, formInput, formClone, linkDir, cellValue,
                tbody = scriptTable.tBodies[0];

            form = document.createElement('form');
            form.method = 'post';
            formInput = document.createElement('input');
            formInput.type = 'hidden';
            formInput.name = 'rp';
            form.appendChild(formInput);
            formInput = document.createElement('button');
            formInput.type = 'submit';
            formInput.title = 'Recheck';
            formInput.value = 'RECHECK';
            formInput.name = 'action';
            formInput.appendChild(document.createTextNode('x'));
            form.appendChild(formInput);

            if (typeof parentPath !== "undefined") {
                row = tbody.insertRow(-1);

                cell = row.insertCell();
                linkDir = document.createElement('a');
                linkDir.href = rootUrl + (parentPath ? '&p=' + encodeURIComponent(parentPath) : '');
                linkDir.appendChild(document.createTextNode('..'));
                cell.appendChild(linkDir);
            }

            for (i in scripts) {
                script = scripts[i];
                row = tbody.insertRow(-1);

                cell = row.insertCell();
                cellValue = i;
                setCellData(row, 'path', cellValue);
                formClone = form.cloneNode(true);
                formClone.getElementsByTagName('input')[0].value = script['full_path'];
                cell.appendChild(formClone);
                cell.appendChild(document.createTextNode(' '));

                if (script['directory']) {
                    linkDir = document.createElement('a');
                    linkDir.href = rootUrl + '&p=' + encodeURIComponent(script['full_path']);
                    linkDir.appendChild(document.createTextNode(i));
                    cell.appendChild(linkDir);
                } else {
                    cell.appendChild(document.createTextNode(i));
                }

                cell = row.insertCell();
                cellValue = script['memory_consumption'];
                setCellData(row, 'size', cellValue);
                cell.appendChild(document.createTextNode(formatSize(cellValue)));

                cell = row.insertCell();
                cellValue = script['hits'];
                setCellData(row, 'hits', cellValue);
                cell.appendChild(document.createTextNode(formatHits(cellValue)));

                cell = row.insertCell();
                cellValue = script['last_used_timestamp'];
                setCellData(row, 'lastused', cellValue);
                cell.appendChild(document.createTextNode(formatTime(cellValue)));

                cell = row.insertCell();
                cellValue = script['timestamp'];
                setCellData(row, 'timestamp', cellValue);
                cell.appendChild(document.createTextNode(formatTime(cellValue)));
            }
        };

        function setCellData(row, key, value) {
            if (row.dataset) {
                row.dataset[key] = value;
            } else {
                row.setAttribute('data' + key, value);
            }
        };

        function getCellData(row, key) {
            if (row.dataset) {
                return row.dataset[key];
            } else {
                return row.getAttribute('data-' + key);
            }
        };

        function updateScriptsPath(path, e) {
            var dirs = getDirs(path),
                scriptsPtr = scripts,
                parent = getParentDir(path);

            for (var i = 0; i < dirs.length; i++) {
                if (!dirs[i]) {
                    continue;
                }

                if (!scriptsPtr[dirs[i]]) {
                    return;
                }

                scriptsPtr = scriptsPtr[dirs[i]]['children'];
            }

            if (!scriptsPtr) {
                return;
            }

            if (e) {
                e.preventDefault();
            }

            if (!scriptTable.caption) {
                scriptTable.createCaption();
            }

            scriptTable.caption.innerHTML = '';
            if (path) {
                renderCurrentPath(scriptTable.caption, path);
            }
            while (scriptTable.tBodies[0].rows.length) {
                scriptTable.tBodies[0].deleteRow(0);
            }

            renderScripts(scriptsPtr, parent);
            reorderScripts();
        };

        function handlePathClick(e) {
            var path = e.target.href.match(/p=([^&]*)(?:&|$)/);
            if (!path) {
                path = ['', ''];
            }
            
            path = decodeURIComponent(path[1]);

            if (window.history.pushState) {
                window.history.pushState({path: path}, '', e.target.href);
            }

            updateScriptsPath(path, e);
        };

        function reorderScripts() {
            if (!orderActive) {
                return;
            }

            var rows = [], 
                index = getCellData(orderActive, 'index'), 
                rowOffset = 0;

            // do not sort parent directory link
            if (scriptTable.tBodies[0].rows.length) {
                if (scriptTable.tBodies[0].rows[0].cells[0].firstChild.nodeName === 'A' && scriptTable.tBodies[0].rows[0].cells[0].firstChild.innerHTML === '..') {
                    rowOffset = 1
                }
            } 

            while (scriptTable.tBodies[0].rows.length > rowOffset) {
                rows.push(scriptTable.tBodies[0].rows[rowOffset]);
                scriptTable.tBodies[0].deleteRow(rowOffset);
            }

            rows.sort(function(a, b) {
                var aValue = getCellData(a, index), bValue = getCellData(b, index);

                if (index !== 'path') {
                    if (orderReverse) {
                        return bValue - aValue;
                    }

                    return aValue - bValue;
                } else {
                    if (orderReverse) {
                        return bValue.localeCompare(aValue);
                    }

                    return aValue.localeCompare(bValue);
                }
            });

            for (var i = 0; i < rows.length; ++i) {
                scriptTable.tBodies[0].appendChild(rows[i]);
            }
        };

        function orderScripts(e) {
            if (e.target == orderActive) {
                orderReverse = !orderReverse;
                orderActive.innerHTML = orderActive.innerHTML.replace(/.{2}$/, '');
            } else {
                if (orderActive) {
                    orderActive.innerHTML = orderActive.innerHTML.replace(/.{2}$/, '');
                }
                orderActive = e.target;
            }

            orderActive.innerHTML = orderActive.innerHTML.replace(/$/, orderReverse ? ' ↑' : ' ↓');

            reorderScripts();
        };

        scriptTable.onclick = function(e) {
            if (e.target.nodeName === 'A') {
                handlePathClick(e);
            } else if (e.target.nodeName === 'TH') {
                orderScripts(e);
            }
        };

        window.opcacheScripts = scripts;

        window.onpopstate = function(e) {
            var path = e.state && e.state.path || '';
            updateScriptsPath(path);
        };
    })(window);
    </script>
</section>
<?php
        return ob_get_clean();
    }
}

class Page extends View
{
    protected $opcache;
    
    protected $view = '';
        
    protected $messages = array();
    
    protected $title = '';
    
    protected $content = array();
    
    public function __construct(Opcache $opcache, $view, $viewParams = array())
    {
        $this->opcache = $opcache;
        $this->view = $view;
        $this->viewParams = $viewParams;
    }
    
    public function addMessage($msg)
    {
        $this->messages[] = $msg;
        return $this;
    }
    
    public function addContent($content)
    {
        $this->content[] = $content;
    }
    
    public function getTitle($withSuffix = false)
    {
        $title = $this->title;
        
        if ($withSuffix) {
            $title .= ' - OPcache Control Panel';
        }
        
        return $title;
    }
    
    public function setTitle($title)
    {
        $this->title = $title;
        return $this;
    }
    
    public function __toString()
    {
        ob_start() ?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width">
    <meta name="ROBOTS" content="NOINDEX,NOFOLLOW,NOARCHIVE" />
    <title><?php echo $this->getTitle(true) ?></title>
    <style type="text/css">
/*!
 * Bootstrap v2.3.2
 *
 * Copyright 2012 Twitter, Inc
 * Licensed under the Apache License v2.0
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Designed and built with all the love in the world @twitter by @mdo and @fat.
 */
 
.clearfix {
    *zoom: 1;
}
.clearfix:before,
.clearfix:after {
    display: table;
    content: "";
    line-height: 0;
}
.clearfix:after {
    clear: both;
}
article,
aside,
details,
figcaption,
figure,
footer,
header,
hgroup,
nav,
section {
    display: block;
}
html {
    font-size: 100%;
    -webkit-text-size-adjust: 100%;
    -ms-text-size-adjust: 100%;
}
a {
    border-bottom:1px solid;
}
a:focus, button:focus {
    outline: thin dotted #333;
    outline-offset: -2px;
}
a:hover,
a:active {
    outline: 0;
}
button::-moz-focus-inner,
input::-moz-focus-inner {
    padding: 0;
    border: 0;
}
button,
html input[type="button"],
input[type="reset"],
input[type="submit"] {
    -webkit-appearance: button;
    cursor: pointer;
}
label,
select,
button,
input[type="button"],
input[type="reset"],
input[type="submit"],
input[type="radio"],
input[type="checkbox"] {
    cursor: pointer;
}

.navbar .brand {
    margin-right:.75rem;
    float: left;
    display: block;
    height: 1.5rem;
    padding: .75rem .75rem .75rem 1.5rem;
}
.navbar .brand:hover,
.navbar .brand:focus {
    text-decoration: none;
}
.navbar-fixed-top .navbar-inner {
    margin:0 auto;
}
.navbar .nav {
    position: relative;
    left: 0;
    display: block;
    float: left;
    margin: 0 10px 0 0;
}
.navbar .nav > li {
    float: left;
}
.navbar .nav > li > a,
.navbar .nav > li > button {
    float: none;
    padding: .75rem;
    font-size: inherit;
    line-height: inherit;
}
.navbar .nav > li > a:focus,
.navbar .nav > li > a:hover {
    color: #333333;
}
.navbar .nav > .active > a {
    box-shadow: inset 0 3px 8px rgba(0, 0, 0, 0.125);
}
.navbar .brand,
.navbar .nav > li > a,
.navbar .nav > li > button {
    color: #E2E4EF;
    border:0;
    text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.25);
    background: transparent;
}
.navbar .nav > li > a:hover,
.navbar .nav > li > button:hover,
.navbar .nav > li > a:focus,
.navbar .nav > li > button:focus {
    color: #fff;
}
.navbar .nav > li > a:focus,
.navbar .nav > li > a:hover {
    background-color: transparent;
    color: #fff;
}
.navbar .nav .active > a,
.navbar .nav .active > a:hover,
.navbar .nav .active > a:focus {
    color: #fff;
    background-color: #4F5B93;
}
@-ms-viewport {
    width: device-width;
}
.hidden {
    display: none;
    visibility: hidden;
}

body, input, textarea {
        font-family: "Source Sans Pro", Helvetica, Arial, sans-serif;
}

body {
        font-size: 1rem;
        line-height: 1.5rem;
        padding-left:0;
        padding-right:0;
        padding-bottom:0;
        margin:0;
}

button,
input,
select,
textarea {
        font-family: inherit;
        font-size: 100%;
        margin: 0;
}
button,
input {
        line-height: normal;
}
h1, h2, h3, h4, h5, h6 {
    line-height: 3rem;
    margin:0 0 1.5rem;
    overflow:hidden;
}
h1 {
    font-size: 1.5rem;
}
h2 {
    font-size: 1.25rem;
}
h3 {
    font-size:1.125rem;
}
h4, h5, h6 {
    font-size: 1rem;
}
p {
    margin:0 0 1.5rem
}
ul, ol {
        margin:0 0 1.5rem 1.5rem;
        padding:0;
}
p:empty {
        margin:0;
        height:0;
        display:none;
}
abbr {
        border-bottom:1px dotted;
        cursor: help;
}
a {
        text-decoration:none;
}

.navbar a {
        border:0;
}

.navbar {
    border-bottom:.25rem solid;
    overflow: visible;
    *position: relative;
    *z-index: 2;
}
.warn {
        padding: .75rem 1rem;
        margin: 1.5rem 0 1.5rem 1.5rem;
        border-top: .1875rem solid;
}

#layout {
        margin: 0 auto 1.5rem;
        clear:both;
}
#layout-content {
    padding:1.5rem;
    -moz-box-sizing:border-box;
    box-sizing:border-box;
}

/* Footer styling */

footer {
        clear: both;
        overflow: auto;
        border-top: .25rem solid;
        padding: .75rem 0;
}

footer ul {
        margin:0;
        padding:0;
}

footer .footmenu li {
        display: inline;
}

footer a {
        margin: 0 .5rem;
}


/* Standard Tables */

table {
    border-collapse: collapse;
    border-spacing: 0;
    margin:0 0 1.5rem;
}
table td {
    vertical-align:top;
}
em {
        font-weight:normal;
        font-style:italic;
}
strong {
        font-weight:bold;
        font-style:normal;
}

.navbar ul {
        list-style:none;
}
.navbar a {
        display:inline-block;
}

.title {
    position:relative;
    padding:0 .75rem;
    clear:both;
}
.title a {
    border:0;
}

.center {
        text-align:center;
}

/* {{{ Warning and notes */

div.tip,
div.warning,
div.caution,
blockquote.note {
    padding: .75rem;
    margin: 1.5rem 0;
    overflow: hidden
}

blockquote.note strong.note {
    font-size: 1.125rem;
}
div.tip strong.tip,
div.warning strong.warning,
div.caution strong.caution {
    float: left;
    margin-right: 0.5rem;
    font-size: 1.125rem;
}
blockquote.note p,
div.caution p,
div.warning p,
div.tip p {
     margin: 0;
}

/* }}} */

/* {{{ Tables */
.docs th {
        text-align: left;
}

.docs td,
.docs th {
        padding: .25rem .5rem;
}

.doctable {
        width: 100%;
        margin:0 0 1.5rem;
}
.doctable thead tr {
        border:1px solid;
}
.doctable tr {
        border:1px solid;
}

.doctable.pivot tr {
    border: 0;
}
.doctable.pivot tbody th,
.doctable.pivot tbody td {
    border: 1px solid;
}

/* }}} */

/* {{{ lists */
.docs ol {
        list-style-type: decimal;
}
/* }}} */
@media (min-width: 768px) {

    .navbar-fixed-top {
        top: 0;
        -webkit-transform: translateZ(0);
        -moz-transform: translateZ(0);
        transform: translateZ(0);
    }
    body {
        margin:3.25rem 0 0;
    }

    #layout-content {
        float:left;
        width:100%;
    }
    .navbar-fixed-top {
        position: fixed;
        right: 0;
        left: 0;
        z-index: 1030;
        margin-bottom: 0;
    }
}
@media (min-width: 1200px) {
    .navbar-inner,
    #layout {
        width:1170px;
    }
}
@media (min-width: 1500px) {
    .navbar-inner,
    #layout {
        width:1440px;
    }
}

@media (max-width:767px) {
    .navbar-fixed-top .container {
        width:auto;
    }

    .navbar .nav {
        margin-right: 0;
    }

    .navbar .brand {
        float: left;
    }
    
    .navbar .nav > li, .footmenu > li {
        display: block;
        text-align: center;
    }
    
    .navbar .nav > li a, .footmenu > li > a {
        display: block;
    }

}

@media (min-width:1548px) {
    #layout {
        padding-right:0;
    }
}

/**
 *
 *  COLORS:       | HEX     |
 * ---------------+---------+
 *  light-blue    | #E2E4EF |
 * ---------------+---------+
 *  medium-blue   | #8892BF |
 * ---------------+---------+
 *  dark-blue     | #4F5B93 |
 * ---------------+---------+
 *
 */


html {
    background-color: #333;
}

body {
    background:#C4C9DF;
    color: #333;
}
#layout-content {
    background:#fff;
    border-color:#ccc;
}

abbr {
    border-color: #8892BF;
}

h1, h2, h3, h4, h5, h6 {
    font-weight:bolder;
    color:#333
}
h1:not(.title):after,
h2:not(.title):after,
h3:not(.title):after {
    display:table;
    width:100%;
    content:" ";
    margin-top:-1px;
    border-bottom:1px dotted;
}
.title h1:after,
.title h2:after,
.title h3:after {
    display:none;
}

a:link,
a:visited {
    color: #369;
}

a:hover,
a:focus {
    color: #693;
    border-bottom-color:#693;
}

ul {
    list-style-type: disc;
}

ol {
    list-style-type: decimal;
}
.title {
    color: #333;
    background: #E2E4EF;
    border-radius:0 0 2px 2px;
    box-shadow: inset 0 0 00 1px rgba(0,0,0,.1);
}
.title:before {
    content:" ";
    display:block;
    position:absolute;
    left:0;
    border-top:2px solid #4F5B93;
    width:100%;
}
.title a {
    color: #333;
}

/* {{{ Warnings, Tips and Notes */
div.tip {
    background:#D9E6F2;
    border-color: #B3CCE6;
    border-bottom-color:#9FBFDF;
}
blockquote.note {
    background-color: #E6E6E6;
    border-color: #ccc;
}
div.caution {
    background: #fcfce9;
    border-color: #e2e2d1;
}
div.warning {
    background:#F4DFDF;
    border-color: #EABFBF;
}

div.tip,
blockquote.note,
div.caution,
div.warning {
    box-shadow:inset 0 0 0 1px rgba(0,0,0,.1);
    border-radius:0 0 2px 2px;
}
div.warning a:link,
div.warning a:visited,
div.warning h2,
div.warning h3 {
    color:#936;
}
div.warning a:hover,
div.warning a:focus {
    color:#693;
    border-color:#693;
}
/* }}} */


/* {{{ Navbar */
.navbar {
    border-color:#4F5B93;
    background:#8892BF;
    box-shadow: 0 .25em .25em  rgba(0,0,0,.1);
}
.navbar .brand {
    color: #333;
    font-weight: 600;
    font-style: italic;
    font-size: 1.4em;
}
.navbar a {
    text-shadow: 0 1px 0 #fff;
}
/* }}} */

/* {{{ Tables */
.doctable {
    border-color: #ccc;
}
.doctable thead tr{
    border-color: #C4C9DF;
    border-bottom-color: #8892BF;
    color: #333;
}
.doctable th {
    background-color: #C4C9DF;
}
.doctable tr {
    border-color: #ccc
}
.doctable tbody tr:nth-child(odd) {
    background-color: #ffffff;
}
.doctable tbody tr:nth-child(even) {
    background-color: #E6E6E6;
}
.doctable.pivot tbody th {
    border-color: #C4C9DF #8892BF #C4C9DF #C4C9DF;
    color: #333;
}
.doctable.pivot tbody td {
    border-color: #ccc
}
/* }}} */

/* {{{ Footer */
footer {
    background-color: #333;
    border-top-color: #8892BF;
}
footer a {
    color:#ccc;
}
footer a:link,
footer a:visited {
    color: #ccc;
    border-bottom: none;
}
footer a:hover,
footer a:focus {
    color: #999;
    border-bottom: none;
}
/* }}} */

.graph-set {
    margin: 0 -10px;
}

.graph-set .graph {
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    box-sizing: border-box;
    float: left;
    width: 100%;
    padding: 10px;
}

@media (min-width: 480px) {
    .graph-set .graph {
        width: 50%;
    }
}

@media (min-width: 768px) {
    .graph-set .graph {
        width: 25%;
    }
}

.graph table {
    width: 100%;
    height: 175px;
    position: relative;
}

.graph table td {
    vertical-align: middle;
    border: 0;
    padding: 0 0 0 5px;
}

.graph table .total {
    padding: 0 5px 0 0;
    min-width: 2em;
}

.graph table .total span {
    background: #fff;
    padding: 2px 0;
    position: relative;
}

.graph table .total:before {
    content: "";
    border: 1px dashed #888;
    border-right: 0;
    display: block;
    position: absolute;
    width: 0.75em;
    bottom: 0;
    top: 0;
    left: 1em;
}

.graph .actual {
    text-align: right; 
    font-weight: bold;
    padding: 0 5px 0 0;
    white-space: nowrap;
}
.graph .bar {width:40%; text-align: center; padding:0 5px; color:#fff;}
    .graph .red {background:#ee0000;}
    .graph .green {background:#00cc00;}
    .graph .brown {background:#8B4513;}

    tr.disabled { text-decoration: line-through; }
.doctable ul { margin-bottom: 0; }
.doctable form { display: inline; }

.table-overflow { overflow: auto; }

a.active { font-weight: bolder; }

#files th { cursor: pointer; }
#files caption { margin-bottom: 1em; }
#files caption span { padding: 0 0.4em 0 0; }

    </style>
</head>
<body class="docs">

<nav id="head-nav" class="navbar navbar-fixed-top">
    <div class="navbar-inner clearfix">
        <a href="<?php echo $this->getUrl() ?>" class="brand">OPcache Control Panel</a>
        <?php if ($this->opcache->isAvailable()): ?>
        <form method="post">
            <ul class="nav">
                <li<?php if ($this->view == 'ALL'): ?> class="active" <?php endif; ?>><a href="<?php echo $this->getUrl(array('query' => array('view' => 'ALL'))) ?>">Details</a></li>
                <li<?php if ($this->view == 'FILES'): ?> class="active" <?php endif; ?>><a href="<?php echo $this->getUrl(array('query' => array('view' => 'FILES'))) ?>">Files</a></li>
                <li><button type="submit" name="action" value="RESET" onclick="return confirm('RESET cache?')">Reset</button></li>
                <?php if ($this->opcache->canRecheck()): ?>
                <li><button type="submit" name="action" value="RECHECK" onclick="return confirm('Recheck all files in the cache?')">Recheck</button></li>
                <?php endif; ?>
                <li><a href="<?php echo $this->getViewUrl() ?>">Refresh</a></li>
            </ul>
    </form>
    <?php endif; ?>
    </div>
</nav>

<div id="layout">
<section id="layout-content">
    <?php foreach ($this->messages as $msg): ?>
    <blockquote class="note">
        <?php echo $this->escapeHtml($msg) ?>
    </blockquote>
    <?php endforeach; ?>
    <h1><?php echo $this->getTitle() ?></h1>
    <?php 
    foreach ($this->content as $content) {
        echo $content;
    }
    ?>
</section>
</div>

<footer>
    <div class="container footer-content">
        <div class="row-fluid">
        <ul class="footmenu">
            <li><a href="http://docs.php.net/manual/en/book.opcache.php">PHP Manual</a></li>
            <li><a href="http://docs.php.net/manual/en/opcache.configuration.php">Configuration</a></li>
        <li><a href="http://docs.php.net/manual/en/ref.opcache.php">Functions</a></li>
        <li><a href="https://wiki.php.net/rfc/optimizerplus">PHP RFC</a></li>
        <li><a href="http://pecl.php.net/package/ZendOpcache">PECL Extension</a></li>
        <li><a href="https://github.com/zend-dev/ZendOptimizerPlus/">Extension Source</a></li>
        <li><a href="https://gist.github.com/ck-on/4959032/?ocp.php">OCP Latest</a></li>
        </ul>
        </div>
    </div>
</footer>

<script type="text/javascript">
    WebFontConfig = {
        google: { families: [ 'Source+Sans+Pro:400,600,400italic,600italic:latin,latin-ext' ] }
    };
    (function() {
        var wf = document.createElement('script');
        wf.src = ('https:' == document.location.protocol ? 'https' : 'http') +
            '://ajax.googleapis.com/ajax/libs/webfont/1/webfont.js';
        wf.type = 'text/javascript';
        wf.async = 'true';
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(wf, s);
    })(); </script>
</body>
</html>
<?php
        return ob_get_clean();
    }
}

class App {
    const DEFAULT_PASSWORD = 'password';

    protected $time;

    protected $msgs = array(
        'SUCCESS_RESET' => 'The OPcache has been successfully reset.',
        'ERROR_INVALID_VERSION' => 'Sorry, this function requires a newer version of OPcache.',
        'SUCCESS_RECHECK' => 'The OPcache has been successfully invalidated.',
        'SUCCESS_RECHECK_PATH' => 'The requested path has successfully been invalidated in the OPcache',
    );

    protected $views = array(
        'GRAPHS',
        'ALL',
        'FILES',
    );

    protected $view = '';
    
    protected $opcache;

    protected $status;

    protected $authOptions = array(
        'enabled' => false,
        'username' => 'ocp',
        'password' => self::DEFAULT_PASSWORD,
        'realm' => 'OCP Login',
    );

    public function __construct($config = array())
    {
        $this->opcache = new Opcache();

        if (isset($config['test'])) {
            $this->opcache->setIsTest($config['test']);
        }

        if (isset($config['auth']) && is_array($config['auth'])) {
            $this->authOptions = array_merge($this->authOptions, $config['auth']);
        }
    }

    protected function route() 
    {
        if (!$this->opcache->isAvailable()) {
            $this->view = 'UNAVAILABLE';
        } elseif (!empty($_GET['view']) && in_array($_GET['view'], $this->views)) {
            $this->view = $_GET['view'];
        }
    }

    public function getViewParams()
    {
        $params = array();

        if ($this->view) {
            $params['view'] = $this->view;

            switch ($this->view) {
                case 'FILES':
                    if (isset($_GET['p'])) {
                        $params['p'] = $_GET['p'];
                    }

                    if (isset($_GET['md'])) {
                        $params['md'] = $_GET['md'];
                    }
                    break;
            }
        }

        return $params;
    }

    protected function postRedirectGet($urlParts)
    {
        $urlModel = new Url();
        
        if ($_SERVER['SERVER_PROTOCOL'] === 'HTTP/1.1') {
            $url = $urlModel->getUrl($urlParts, true);
            header("Location: ${url}", true, 303);
        } else {
            $url = $urlModel->getUrl($urlParts);
            header("Location: ${url}", true, 302);
        }
    }
    
    protected function preDispatch()
    {
        $msgs = array();

        if ($this->authOptions['enabled']) {
            if ($this->authOptions['password'] !== self::DEFAULT_PASSWORD) {
                $user = $pass = '';

                if (isset($_SERVER['PHP_AUTH_USER']) && isset($_SERVER['PHP_AUTH_PW'])) {
                    $user = $_SERVER['PHP_AUTH_USER'];
                    $pass = $_SERVER['PHP_AUTH_PW'];
                } elseif (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
                     $auth = $_SERVER['HTTP_AUTHORIZATION'];
                    list($user, $pass) = explode(':', base64_decode(substr($auth, strpos($auth, " ") + 1)));
                } elseif (!empty($_SERVER['Authorization'])) {
                    $auth = $_SERVER['Authorization'];
                    list($user, $pass) = explode(':', base64_decode(substr($auth, strpos($auth, " ") + 1)));
                }

                if (!$user || !$pass || $user !== $this->authOptions['username'] || $pass !== $this->authOptions['password']) {
                    header('HTTP/1.1 401 Unauthorized');
                    header('WWW-Authenticate: Basic realm="' . $this->authOptions['realm'] . '"');
                    echo '<html><body><h1>401 Unauthorized</h1><p>Wrong username or password.</p></body></html>';
                    exit;
                }
            } else {
                header('HTTP/1.1 500 Application Configuration Error');
                echo '<html><body><h1>Application Configuration Error</h1><p>Use a non-default password.</p></body></html>';
                exit;
            }
        }
        
        if (!empty($_POST['action'])) {
            switch ($_POST['action']) {
                case 'RESET':
                    $this->opcache->reset();
                    $msgs[] = 'SUCCESS_RESET';
                    break;
        
                case 'RECHECK':
                    if ($this->opcache->canRecheck()) {
                        $recheck = false;
                        if (!empty($_POST['rp'])) {
                            $recheck = $_POST['rp'];
                        }
                        $this->opcache->invalidatePath($recheck);
        
                        if ($recheck) {
                            $msgs[] = 'SUCCESS_RECHECK_PATH';
                        } else {
                            $msgs[] = 'SUCCESS_RECHECK';
                        }
                    } else {
                        $msgs[] = 'INVALID_VERSION';
                    }
                    break;
            }
        
            $params = array();
            if (!empty($msgs)) {
                $params['m'] = $msgs;
            }
            $params = array_merge($this->getViewParams(), $params);
        
            $this->postRedirectGet(array('query' => $params));
            exit;
        }
    }
    
    protected function loadMessages(Page $page)
    {
        if (!empty($_GET['m'])) {
            foreach ($_GET['m'] as $msg) {
                if (isset($this->msgs[$msg])) {
                    $page->addMessage($this->msgs[$msg]);
                }
            }
        }
    }
    
    protected function indexAction()
    {
        $page = new Page($this->opcache, $this->view, $this->getViewParams());
        
        $this->loadMessages($page);
        
        $page->setTitle('Statistics/Configuration');
        $page->addContent(new Graphs($this->opcache));
        
        if ($this->view == 'GRAPHS') {
            echo $page;
            return;
        }
        
        $page->addContent(new Info($this->opcache));
        
        if ($this->view == '') {
            echo $page;
            return;
        }
        
        $page->setTitle($page->getTitle() . ' (Full)');
        
        $page->addContent(new Stats($this->opcache));
        $page->addContent(new Config($this->opcache));
        
        echo $page;
    }
    
    protected function filesAction()
    {
        $treeView = true;
        $path = isset($_GET['p']) ? $_GET['p'] : '';
        
        if (isset($_GET['md']) && $_GET['md'] == 'list') {
            $treeView = false;
        }
        
        if (isset($_GET['format']) && $_GET['format'] == 'json') {
            header('Content-Type: application/json');
            echo json_encode($this->opcache->getCachedScripts($path, $treeView));
            return;
        }
        
        $viewParams = $this->getViewParams();
        
        $page = new Page($this->opcache, $this->view, $viewParams);
        
        $this->loadMessages($page);
        
        $page->setTitle('Cached Scripts');
        $page->addContent(new Files($this->opcache, $viewParams, $treeView));
        
        echo $page;
    }
    
    protected function invalidAction()
    {
        $page = new Page($this->opcache, $this->view, $this->getViewParams());
        $page->setTitle('OPcache not detected');
        
        echo $page;
    }
    
    public function dispatch()
    {
        switch ($this->view) {
            case '':
            case 'GRAPHS':
            case 'ALL':
                $this->indexAction();
                break;
            case 'FILES':
                $this->filesAction();
                break;
            default:
                $this->invalidAction();
        }
    }

    public function run() 
    {
        // weak block against indirect access
        if (count(get_included_files())>1 || php_sapi_name()=='cli' || empty($_SERVER['REMOTE_ADDR'])) {
            die;
        }
        
        $this->route();
        $this->preDispatch();
        $this->dispatch();
    }
}

}
