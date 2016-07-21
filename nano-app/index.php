<?php

require_once __DIR__ . '/Counter.php';

$db = new PDO(
    getenv('DB_DSN') ?: 'sqlite:/tmp/test.db',
    getenv('DB_USER') ?: null,
    getenv('DB_PASSWD') ?: null
);

$counter = new Counter($db);

header('Content-Type:text/plain');
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Methods: GET, PUT, DELETE, OPTIONS");
header("X-Instance: " . (getenv('INSTANCE_ID') ?: 'unknown'));

switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET': echo $counter->getCurrentCounter(); break;
    case 'PUT': $counter->increaseCounter(); echo $counter->getCurrentCounter(); break;
    case 'DELETE': $counter->reset(); echo "OK"; break;
}