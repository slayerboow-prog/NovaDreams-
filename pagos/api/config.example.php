<?php
/**
 * Copia este archivo como "config.php" (mismo directorio) y rellena tus claves reales.
 * NUNCA subas config.php a git — ya está en .gitignore.
 *
 * Dónde conseguir cada clave:
 *  - Stripe:   https://dashboard.stripe.com/apikeys  (usa las de modo TEST hasta que todo funcione)
 *  - PayPal:   https://developer.paypal.com/dashboard/applications  (crea una app, copia Client ID y Secret)
 *  - Amazon Pay: https://sellercentral.amazon.com/apps/store/detail/GVA6XVLZ1V3ME8T (Amazon Pay Integration Central)
 *               requiere una cuenta de comerciante de Amazon Pay ya aprobada.
 */

return [
    // --- Stripe ---
    'stripe' => [
        'secret_key'      => 'PEGA_AQUI_TU_STRIPE_SECRET_KEY',      // empieza por sk_test_ o sk_live_
        'publishable_key' => 'PEGA_AQUI_TU_STRIPE_PUBLISHABLE_KEY', // empieza por pk_test_ o pk_live_
    ],

    // --- PayPal ---
    'paypal' => [
        'client_id'   => 'TU_PAYPAL_CLIENT_ID',
        'secret'      => 'TU_PAYPAL_SECRET',
        // 'sandbox' mientras pruebas, 'live' cuando esté listo para cobrar de verdad
        'environment' => 'sandbox',
    ],

    // --- Amazon Pay (rellenar cuando tengas cuenta de comerciante aprobada) ---
    'amazon_pay' => [
        'merchant_id'    => '',
        'public_key_id'  => '',
        'store_id'       => '',
        // 'sandbox' o 'live'
        'environment'    => 'sandbox',
    ],

    // Moneda e importe de ejemplo (ajusta a tu carrito real)
    'currency' => 'eur',
];
