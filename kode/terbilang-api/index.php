<?php declare(strict_types=1);

require __DIR__ . '/vendor/autoload.php';

use RioAstamal\AngkaTerbilang\Terbilang;

/**
 * @param array $event
 * @see https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html for example
 * @return callable
 */
return function ($event)
{
    $angka = $event['queryStringParameters']['angka'] ?? '0';
    $options = isset($event['queryStringParameters']['pretty']) ? JSON_PRETTY_PRINT : 0 ;

    $response = [
        'angka' => $angka,
        'terbilang' => Terbilang::create()->t($angka)
    ];

    return json_encode($response, $options);
};