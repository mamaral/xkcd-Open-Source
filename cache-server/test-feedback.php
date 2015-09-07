<?php

// include auto-loader
require __DIR__ . '/vendor/autoload.php';

// load configuration
require('config.inc.php');

// set up our database connection
$db = new PDO(DB_DSN, DB_USER, DB_PASSWORD);

// create an instance of the feedback class
$feedback = new ApnsPHP_Feedback(ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION, APS_CERT_PATH);
$feedback->connect();

// get device tokens from feedback service
$response = $feedback->receive();

// disconnect from feedback service
$feedback->disconnect();

// loop through the response
foreach ($response as $item) {
	// convert and quote the "before" stamp
	$stamp = $db->quote(date('Y-m-d H:i:s', $item['timestamp']));

	// delete it from the database if the token hasn't been updated since the timestamp of the feedback entry
	$db->exec('delete from devices where token=' . $db->quote($item['deviceToken']) . ' and ((created_at < ' . $stamp . ' and updated_at is null) or (updated_at < ' . $stamp . '))');
}

// done!