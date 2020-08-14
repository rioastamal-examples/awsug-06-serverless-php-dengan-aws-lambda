<?php
/**
 * Lambda function to handle notification from S3 event and then
 * send the info via email (SMTP).
 */
namespace App;
use Tx\Mailer;

class Handler
{
  /**
   * @var array $config - Configuration for the Handler such as
   *      region, endpoint, etc.
   */
  public $config = [];

  /**
   * Constructor
   *
   * @param array $config
   * @return void
   */
  public function __construct(array $config = [])
  {
    $default = [
      'region'      => 'ap-southeast-1',
      'version'     => 'latest',
      'email_addr'  => getenv('AWSUG_EMAIL') ? getenv('AWSUG_EMAIL') : 'rio@rioastamal.net',
      'smtp'        => [
        'host' => getenv('AWSUG_SMTP_HOST') ? getenv('AWSUG_SMTP_HOST') : 'rio@rioastamal.net',
        'port' => getenv('AWSUG_SMTP_PORT') ? getenv('AWSUG_SMTP_PORT') : 587,
        'username' => getenv('AWSUG_SMTP_USER') ? getenv('AWSUG_SMTP_USER') : null,
        'password' => getenv('AWSUG_SMTP_PASSWD') ? getenv('AWSUG_SMTP_PASSWD') : null,
      ]
    ];

    $this->config = array_replace_recursive($default, $config);
  }

  /**
   * Create object from static calls
   *
   * @param array $config
   * @return App\Handler
   */
  public static function create(array $config = [])
  {
    return new static($config);
  }

  /**
   * Handler function which return a response and will be send back to Lambda
   *
   * @param array $event Lambda Event
   * @return String
   */
  public function handle($event)
  {
    $eventTime = $event['Records'][0]['eventTime'];
    $body = sprintf('<h3>Here is the the event info.</h3><pre>%s</pre>', json_encode($event, JSON_PRETTY_PRINT));

    // Send email notification for new file
    $mailer = (new Mailer())
        ->setServer($this->config['smtp']['host'], $this->config['smtp']['port'])
        ->setFrom('Rio Astamal', 'rio@rioastamal.net')
        ->addTo('AWS UG Surabaya', $this->config['email_addr'])
        ->setSubject( sprintf('New file has been uploaded at %s', $eventTime) )
        ->setBody($body)
        ->send();

    $response = [
        'email_status' => (bool)$mailer,
        'requestId' => $event['Records'][0]['responseElements']['x-amz-request-id']
    ];
    return json_encode($response);
  }
}