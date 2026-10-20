<?php
/**
 * Captura (cobra de verdad) un pedido de PayPal ya aprobado por el comprador.
 * Lo llama paypal.Buttons({ onApprove }) con el orderID que devolvió createOrder.
 *
 * POST { "orderID": "5O190127TN364715T" }
 * -> el objeto "capture" completo de PayPal (para que confirmes el pedido en tu BBDD)
 */

require __DIR__ . '/_helpers.php';
nd_cors_and_method('POST');

$config = nd_config();
$pp = $config['paypal'] ?? [];
$base = ($pp['environment'] ?? 'sandbox') === 'live'
    ? 'https://api-m.paypal.com'
    : 'https://api-m.sandbox.paypal.com';

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

$body = nd_json_body();
$orderId = $body['orderID'] ?? '';
if (empty($orderId)) {
    nd_json_error(400, 'Falta orderID');
}

[$captureStatus, $captureData] = nd_http_request(
    "$base/v2/checkout/orders/$orderId/capture",
    'POST',
    [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json',
    ],
    '{}'
);

if ($captureStatus >= 400) {
    nd_json_error($captureStatus, 'Error capturando el pedido en PayPal');
}

// TODO: aquí es donde debes marcar el pedido como pagado en tu base de datos,
// antes de devolver éxito al navegador.
echo json_encode($captureData);
