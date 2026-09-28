<?php
/**
 * Utilidades comunes a todos los endpoints de /pagos/api/.
 * Sin dependencias externas (nada de Composer) para que funcione tal cual
 * en un hosting compartido de Hostinger con PHP nativo + cURL.
 */

function nd_config(): array
{
    $path = __DIR__ . '/config.php';
    if (!file_exists($path)) {
        nd_json_error(500, 'Falta api/config.php. Copia config.example.php a config.php y rellena tus claves.');
    }
    return require $path;
}

function nd_json_error(int $status, string $message): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode(['error' => $message]);
    exit;
}

function nd_json_body(): array
{
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function nd_cors_and_method(string $method = 'POST'): void
{
    header('Content-Type: application/json');
    // Ajusta esto a tu dominio real en producción en vez de '*'.
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
    if ($_SERVER['REQUEST_METHOD'] !== $method) {
        nd_json_error(405, 'Método no permitido');
    }
}

/**
 * Petición HTTP genérica vía cURL. Lanza el body decodificado + código HTTP.
 */
function nd_http_request(string $url, string $method, array $headers = [], ?string $body = null): array
{
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_TIMEOUT        => 20,
    ]);
    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
    }
    $response = curl_exec($ch);
    if ($response === false) {
        $err = curl_error($ch);
        curl_close($ch);
        nd_json_error(502, "Error de conexión: $err");
    }
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $decoded = json_decode($response, true);
    return [$status, is_array($decoded) ? $decoded : ['raw' => $response]];
}
