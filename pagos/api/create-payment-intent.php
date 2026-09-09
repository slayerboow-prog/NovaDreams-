<?php
/**
 * Crea un PaymentIntent de Stripe y devuelve su client_secret.
 * Lo usan tanto el formulario de tarjeta como el botón de Google Pay / Apple Pay
 * (el Payment Request Button de Stripe cubre los dos con este mismo endpoint).
 *
 * POST { "amount_cents": 1999, "currency": "eur" }
 * -> { "clientSecret": "pi_..._secret_..." }
 */

require __DIR__ . '/_helpers.php';
nd_cors_and_method('POST');

$config = nd_config();
$secretKey = $config['stripe']['secret_key'] ?? '';
if (empty($secretKey) || !str_starts_with($secretKey, 'sk_')) {
    nd_json_error(500, 'Configura stripe.secret_key en api/config.php');
}

$body = nd_json_body();

// Importe en la unidad más pequeña de la moneda (céntimos para EUR/USD).
// IMPORTANTE: recalcula/valida el importe real del carrito en el servidor;
// nunca confíes en un importe que venga del navegador sin verificarlo contra
// tu base de datos de precios/carrito.
$amountCents = (int) ($body['amount_cents'] ?? 0);
$currency    = strtolower($body['currency'] ?? $config['currency'] ?? 'eur');

if ($amountCents < 50) { // Stripe exige un mínimo (~0.50 en la mayoría de monedas)
    nd_json_error(400, 'Importe inválido');
}

$payload = http_build_query([
    'amount'                       => $amountCents,
    'currency'                     => $currency,
    // Habilita automáticamente tarjeta, Google Pay y Apple Pay sin configurarlos
    // uno a uno: Stripe decide qué métodos ofrecer según el dispositivo/navegador.
    'automatic_payment_methods[enabled]' => 'true',
]);

[$status, $data] = nd_http_request(
    'https://api.stripe.com/v1/payment_intents',
    'POST',
    [
        'Authorization: Bearer ' . $secretKey,
        'Content-Type: application/x-www-form-urlencoded',
    ],
    $payload
);

if ($status >= 400) {
    nd_json_error($status, $data['error']['message'] ?? 'Error creando el PaymentIntent en Stripe');
}

echo json_encode([
    'clientSecret' => $data['client_secret'],
]);
