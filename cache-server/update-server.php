<?php
// include auto-loader
require __DIR__ . '/vendor/autoload.php';

// load configuration
require('config.inc.php');

// set up our database connection
$db = new PDO(DB_DSN, DB_USER, DB_PASSWORD);

// query the database for our latest comic number
$lastCachedComicNumber = $db->query('select max(num) from comics')->fetchColumn();

// if it's null, we have no comics and will pretend that 0 is our latest ID
if (is_null($lastCachedComicNumber)) {
	$lastCachedComicNumber = 0;
}

// grab the latest comic from xkcd
$latestComic = fetchComicFromUrl('http://xkcd.com/info.0.json');

// if the latest's number is equal to our last cached number, we're done!
if ($latestComic->num == $lastCachedComicNumber) {
	exit; // TODO: does return work here?
}

// NEW XKCDs!!! (sorry, got excited)

// let's generate a prepared statement to insert new comics
$insertStmt = $db->prepare('insert into comics set num = :num, json = :json');

// run in a loop from 1 above the last cached comic number we have, all the way to
// one less than the latest comic's number. we're not including the latest one
// because we already have it.
for ($num = $lastCachedComicNumber + 1; $num < $latestComic->num; $num++) {
	// Randall's a funny guy and skipped 404
	if ($num == 404)
		continue;

	// fetch the comic
	$comic = fetchComicByNumber($num);

	// attach the image attributes (width, height, aspect ratio)
	attachImageAttributesToComic($comic);

	// insert the comic into our database using our prepared statement
	$insertStmt->execute([ ':num' => $comic->num, 'json' => json_encode($comic) ]);
}

// now, as for the latest one we've been sitting on...
// attach the image attributes (width, height, aspect ratio)
attachImageAttributesToComic($latestComic);

// and insert it into our database
$insertStmt->execute([ ':num' => $latestComic->num, 'json' => json_encode($latestComic) ]);

// SWEET! ok. let's push

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

// create an instance of the pusher
$pusher = new ApnsPHP_Push(ApnsPHP_Abstract::ENVIRONMENT_PRODUCTION, APS_CERT_PATH);
$pusher->connect();

// query for the tokens of all test devices
$devicesStmt = $db->query('select token from devices');

// loop through them
while ($deviceToken = $devicesStmt->fetchColumn()) {
	// create a new message
	$message = new ApnsPHP_Message($deviceToken);
	$message->setText('New comic: ' . $latestComic->title);
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
	// prepare an error for unhandled errors
	$unhandledErrors = [];

	// loop through each error
	foreach ($errors as $error) {
		// if it's an invalid token error (statusCode 8)
		if ($error['ERRORS'][0]['statusCode'] == 8) {
			// remove this token from the database
			$db->exec('delete from devices where token=' . $db->quote($error['MESSAGE']->getRecipient()));
		}

		else {
			// otherwise, we'll add it to the unhandled errors array
			$unhandledErrors[] = $error;
		}
	}

	if (!empty($unhandledErrors)) {
		echo "Unhandled push errors:\n";
		var_dump($unhandledErrors);
	}
}

// DONE!

function fetchComicByNumber($number) {
	// grab the comic and return it
	return fetchComicFromUrl('http://xkcd.com/' . $number . '/info.0.json');
}

function fetchComicFromUrl($url) {
	// grab the comic. or at least what should be.
	$comic = fetchJsonFromUrl($url);

	// ensure we got back an object, and not some other JSON thingy
	if (!is_object($comic)) {
		throw new Exception('Server returned something that is not an object');
	}

	// ensure the "comic" has a number
	// (our final "is this really a comic?" test)
	if (!isset($comic->num)) {
		throw new Exception('Server returned an object but it doesn\'t look like a comic');
	}

	// return the comic
	return $comic;
}

function fetchJsonFromUrl($url, $statusCode = null) {
	// fetch data from the URL
	$statusCode = fetchDataFromUrl($url, $data);

	// try and decode the json
	$json = @json_decode($data);

	// if we got null back, the JSON failed to decode,
	// and we should throw an exception
	if (is_null($json)) {
		throw new Exception('Could not parse JSON');
	}

	// return the decoded JSON
	return $json;
}

function fetchDataFromUrl($url, &$data) {
	// we're going to use this cURL handle over and over again,
	// especially since we're expecting to call the same host
	// repeatedly. this will make subsequent requests much faster.
	static $ch;

	// if our cURL handle isn't set yet, let's do our initial setup
	if (!isset($ch)) {
		$ch = curl_init();
		curl_setopt_array($ch, [
			// we need to get data back from this, not have it output
			CURLOPT_RETURNTRANSFER => true,

			// if it takes longer than 10 seconds to connect to the remote host
			// we probably have a connection issue (or they do), and we can give up
			CURLOPT_CONNECTTIMEOUT => 10
		]);
	}

	// set our request URL
	curl_setopt($ch, CURLOPT_URL, $url);

	// execute the request, setting the data on our referenced variable
	$data = curl_exec($ch);

	// return the HTTP status code for that request
	return curl_getinfo($ch, CURLINFO_HTTP_CODE);
}

function attachImageAttributesToComic($comic) {
	// find the image extension. we'll need it to use the right image decoding function.
	// we're going to just expect that the image will have an extension and not handle
	// the case of it not having one. because there's nothing we can do about it.
	preg_match('/\.([a-z]+)$/i', $comic->img, $matches);

	// we will force it to lowercase though. just in case.
	$imageExtension = strtolower($matches[1]);

	// fetch the image into memory, using the image URL, and hope for the best
	if ($imageExtension == 'jpg' || $imageExtension == 'jpg' /* you never know...*/ ) {
		$img = @imagecreatefromjpeg($comic->img);
	}
	elseif ($imageExtension == 'png') {
		$img = @imagecreatefrompng($comic->img);
	}
	elseif ($imageExtension == 'gif') {
		$img = @imagecreatefromgif($comic->img);
	}
	else {
		throw new Exception('A comic contains an image in a format that is not supported.');
	}

	// if we didn't get an image, we suck
	if ($img === false) {
		throw new Exception('Unable to load image for comic');
	}

	// set the image width, height, and aspect ratio on the comic
	$comic->img_w = imagesx($img);
	$comic->img_h = imagesy($img);
	$comic->img_aspect_ratio = $comic->img_w / $comic->img_h;

	// unload the image from memory
	imagedestroy($img);
}
