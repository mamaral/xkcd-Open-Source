<?php

// include auto-loader
require __DIR__ . '/vendor/autoload.php';

// load configuration
require('config.inc.php');

// create an instance of the pusher
$pusher = new ApnsPHP_Push(ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION, APS_CERT_PATH);
$pusher->connect();

// set up our database connection
$db = new PDO(DB_DSN, DB_USER, DB_PASSWORD);

// query for the tokens of all test devices
$devicesStmt = $db->query('select token from devices where is_test_device=1');

// loop through them
while ($deviceToken = $devicesStmt->fetchColumn()) {
	// create a new message
	$message = new ApnsPHP_Message($deviceToken);
	$message->setText('Test push notification');
	$message->setSound('silent.m4a');
	$message->setBadge(1);
	$message->setContentAvailable(true);

	// add it to the queue
	$pusher->add($message);
}

// send all the messages
$pusher->send();

// and disconnect
$pusher->disconnect();

// were there any errors?
$errors = $pusher->getErrors();
if (!empty($errors)) {
	echo "Push errors:\n";
	var_dump($errors);
}

// done!