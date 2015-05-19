<?php

// make sure the client provided us with a token
if (!isset($_POST['token'])) {
	header('HTTP/1.1 400 Bad Request');
	echo "'token' is a required parameter";
	exit;
}

// get the token from the request
$token = $_POST['token'];

// make sure it's a number
if (!preg_match('/^[0-9a-f]{64}$/', $token)) {
	header('HTTP/1.1 400 Bad Request');
	echo "unsupported format for 'token' parameter";
	exit;
}

// load configuration
require('config.inc.php');

// set up our database connection
$db = new PDO(DB_DSN, DB_USER, DB_PASSWORD);

// get now as a string for our database
$dateString = date('Y-m-d H:i:s');

// update an existing token, if we have one
$tokenStmt = $db->prepare('update devices set updated_at=:updated_at where token=:token');
$success = $tokenStmt->execute([ 'updated_at' => $dateString, 'token' => $token ]);

// did that fail?
if (!$success) {
	$errorInfo = $tokenStmt->errorInfo();
	header('HTTP/1.1 500 Internal Server Error');
	echo 'Token update failed: ' . $errorInfo[0] . ' ' . $errorInfo[2] . ' [' . $errorInfo[1] . ']';
	exit;
}

// if no rows were affected, we need to insert the token
if ($tokenStmt->rowCount() == 0) {
	// so insert it
	$tokenStmt = $db->prepare('insert into devices set token=:token,created_at=:created_at');
	$success = $tokenStmt->execute([ 'token' => $token, 'created_at' => $dateString ]);

	// did that fail?
	if (!$success) {
		$errorInfo = $tokenStmt->errorInfo();
		header('HTTP/1.1 500 Internal Server Error');
		echo 'Token update failed: ' . $errorInfo[0] . ' ' . $errorInfo[2] . ' [' . $errorInfo[1] . ']';
		exit;
	}
}

// ok we're good. let the client know with a 202.
header('HTTP/1.1 202 Accepted');
