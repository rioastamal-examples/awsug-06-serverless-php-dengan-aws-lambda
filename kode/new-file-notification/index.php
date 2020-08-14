<?php
/**
 * AWS Lambda Handler
 */
require __DIR__ . '/vendor/autoload.php';

// Run for Lambda
if (getenv('AWS_LAMBDA_RUNTIME_API')) {
  App\LambdaRuntime::create()->main();
  exit(0);
}

// Should be run from CLI
$payload = json_decode(file_get_contents('php://STDIN'), $toArray = true);
echo App\Handler::create()->handle($payload);