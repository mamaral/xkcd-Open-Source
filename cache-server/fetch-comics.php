<?php

// make sure the client provided us with a "since" comic #
if (!isset($_GET['since'])) {
	header('HTTP/1.1 400 Bad Request');
	echo "'since' is a required parameter";
	exit;
}

// get the "since" number from the request
$since = $_GET['since'];

// make sure it's a number
if (!preg_match('/^[0-9]+$/', $since)) {
	header('HTTP/1.1 400 Bad Request');
	echo "unsupported format for 'since' parameter";
	exit;
}

// load configuration
require('config.inc.php');

// set up our database connection
$db = new PDO(DB_DSN, DB_USER, DB_PASSWORD);

// query for all comics since the "last" one
$comicsQuery = $db->query('select json from comics where num > ' . $since . ' order by num');

// begin gzipped output
ob_start('ob_gzhandler');

// this is JSON
header('Content-Type: application/json');

// begin the JSON
echo '[';

// we need to keep track of our row index, so we can output commas
// before every element, except the first
$comicIndex = 0;

// loop through the rows, grabbing the JSON text for each
while ($comicJson = $comicsQuery->fetchColumn()) {
	// if it's not the first row, output a comma to separate it from
	// the previous JSON object
	if ($comicIndex > 0) {
		echo ',';
	}

	// output this comic's JSON
	echo $comicJson;

	// increment the index
	$comicIndex++;
}

// and end the JSON
echo ']';

// done!
