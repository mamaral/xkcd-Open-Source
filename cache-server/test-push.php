<?php

// load configuration
require('config.inc.php');

// set up our database connection
$db = new PDO(DB_DSN, DB_USER, DB_PASSWORD);

// create APNS payload
$payload = [
	'aps' => [
		'alert' => 'Test push notification',
		'sound' => 'silent.mp3',
		'badge' => 1,
		'content-available' => 1
	]
];

// encode as JSON, and fix it, since PHP likes to escape quotes, and Apple chokes on it
$payload = str_replace("\/", "/", json_encode($payload));

// get the payload length
$payloadLen = strlen($payload);

// set up the stream context for the TLS connection
$context = @stream_context_create();
@stream_context_set_option($context, 'ssl', 'local_cert', APS_CERT_PATH);

// set up socket
$socket = @stream_socket_client('tls://' . APS_SERVER . ':2195', $errorCode, $errorMsg, 60, STREAM_CLIENT_CONNECT, $context);
if (!$socket) exit('APS socket failed to connect: ' . $errorMsg . ' [' . $errorCode . ']');

// query for all of our device tokens
$devicesStmt = $db->query('select token from devices');

// loop through them
while ($deviceToken = $devicesStmt->fetchColumn()) {
	// push to the device
	fwrite($socket, chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', $payloadLen) . $payload);
}

// close the socket
fclose($socket);