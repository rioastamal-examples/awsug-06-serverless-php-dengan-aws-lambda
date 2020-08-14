<?php
namespace App;

use App\Handler;

class LambdaRuntime
{
  /**
   * Create object from static calls
   *
   * @return App\LambdaRuntime
   */
  public static function create()
  {
    return new static();
  }

  /**
   * Simple abstraction for HTTP GET Lambda invocation
   *
   * @param String $url
   * @return Array
   */
  public function fetch($url)
  {
    $headers = [
      'Content-Type: application/json',
      'User-Agent: BelajarAWS/1.0',
      'Accept: application/json'
    ];
    $options = [
      'http' => [
        'method' => 'GET',
        'header' => implode("\r\n", $headers)
      ]
    ];
    $context = stream_context_create($options);
    $response = file_get_contents($url, false, $context);

    // Parse special variables called $http_response_header
    $requestId = null;

    foreach ($http_response_header as $value) {
      if (preg_match('/Lambda-Runtime-Aws-Request-Id/', $value)) {
        $requestId = trim(explode('Lambda-Runtime-Aws-Request-Id:', $value)[1]);
      }
    }

    return [
      'body' => json_decode($response, $toArray = true),
      'request_id' => $requestId
    ];
  }

  /**
   * Simple abstraction for HTTP POST
   *
   * @param String $url
   * @param String $data
   * @return String
   */
  public function post($url, $data)
  {
    $headers = [
      'Content-Type: application/json',
      'User-Agent: BelajarAWS/1.0',
      'Content-Length: ' . strlen($data)
    ];
    $options = [
      'http' => [
        'method' => 'POST',
        'header' => implode("\r\n", $headers),
        'content' => $data
      ]
    ];

    $context = stream_context_create($options);
    return file_get_contents($url, false, $context);
  }

  /**
   * Lambda main loop
   */
  public function main()
  {
    // AWS_LAMBDA_RUNTIME_API are automatically set by Lambda
    $lambdaRuntimeApi = getenv('AWS_LAMBDA_RUNTIME_API');
    $lambdaBaseUrl = sprintf('http://%s/2018-06-01/runtime/invocation/', $lambdaRuntimeApi);
    $maxLoop = getenv('MAX_LOOP') ?: 10;
    $currentLoop = 0;
    $handler = Handler::create();

    // Inner main loop for execution.
    // So if there's next event it will get execute it immediately
    while (true)
    {
      if (++$currentLoop > $maxLoop) {
        break;
      }

      $nextEvent = $this->fetch($lambdaBaseUrl . 'next');
      $handlerResponse = $handler->handle($nextEvent['body']);

      $responseUrl = sprintf('%s%s/response', $lambdaBaseUrl, $nextEvent['request_id']);
      $lambdaResponse = $this->post($responseUrl, $handlerResponse);
    }
  }
}