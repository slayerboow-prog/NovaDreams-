<?php
/**
 * Devuelve SOLO las claves públicas (nunca las secretas) para que el frontend
 * no tenga que duplicarlas a mano en el JS. Así solo hay un sitio (config.php)
 * donde tocar claves al pasar de test a producción.
 */

require __DIR__ . '/_helpers.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$config = nd_config();

echo json_encode([
    'stripePublishableKey' => $config['stripe']['publishable_key'] ?? '',
    'paypalClientId'       => $config['paypal']['client_id'] ?? '',
    'paypalEnvironment'    => $config['paypal']['environment'] ?? 'sandbox',
    'amazonPay'            => [
        'merchantId'   => $config['amazon_pay']['merchant_id'] ?? '',
        'publicKeyId'  => $config['amazon_pay']['public_key_id'] ?? '',
        'storeId'      => $config['amazon_pay']['store_id'] ?? '',
        'environment'  => $config['amazon_pay']['environment'] ?? 'sandbox',
    ],
    'currency' => $config['currency'] ?? 'eur',
]);
