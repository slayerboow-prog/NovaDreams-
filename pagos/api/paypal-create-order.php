<?php
/**
 * Crea un pedido de PayPal (Orders API v2) y devuelve su ID al frontend,
 * que es lo que espera paypal.Buttons({ createOrder }).
 *
 * POST { "amount": "19.99", "currency": "EUR" }
 * -> { "id": "5O190127TN364715T" }
 */

require __DIR__ . '/_helpers.php';
nd_cors_and_method('POST');

$config = nd_config();
$pp = $config['paypal'] ?? [];
if (empty($pp['client_id']) || empty($pp['secret'])) {
    nd_json_error(500, 'Configura paypal.client_id y paypal.secret en api/config.php');
}

$base = ($pp['environment'] ?? 'sandbox') === 'live'
    ? 'https://api-m.paypal.com'
    : 'https://api-m.sandbox.paypal.com';

// 1) Token OAuth2 (client credentials)
[$tokenStatus, $tokenData] = nd_http_request(
    "$base/v1/oauth2/token",
    'POST',
    [
        'Authorization: Basic ' . base64_encode($pp['client_id'] . ':' . $pp['secret']),
        'Content-Type: application/x-www-form-urlencoded',
    ],
    'grant_type=client_credentials'
);
if ($tokenStatus >= 400) {
    nd_json_error($tokenStatus, 'No se pudo autenticar con PayPal');
}
$accessToken = $tokenData['access_token'];

// 2) Crear el pedido
$body = nd_json_body();
$amount   = $body['amount'] ?? '0.00';       // valida esto contra tu carrito real en el servidor
$currency = strtoupper($body['currency'] ?? $config['currency'] ?? 'EUR');

$orderPayload = json_encode([
    'intent' => 'CAPTURE',
    'purchase_units' => [[
        'amount' => [
            'currency_code' => $currency,
            'value'         => $amount,
        ],
    ]],
]);

[$orderStatus, $orderData] = nd_http_request(
    "$base/v2/checkout/orders",
    'POST',
    [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json',
    ],
    $orderPayload
);

if ($orderStatus >= 400) {
    nd_json_error($orderStatus, 'Error creando el pedido en PayPal');
}

echo json_encode(['id' => $orderData['id']]);
