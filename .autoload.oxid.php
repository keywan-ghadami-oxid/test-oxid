<?php

foreach (glob('.autoload.module.*.php') as $file) {
    require_once $file;
};
