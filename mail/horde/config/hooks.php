<?php

class Horde_Hooks
{
    // Add magnification style
    public function cssfiles($theme)
    {
        return array(
            HORDE_BASE . '/szepenet/magnification.css' => '/szepenet/magnification.css',
        );
    }
}
