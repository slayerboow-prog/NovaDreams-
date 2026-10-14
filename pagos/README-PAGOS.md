# Sistema de pagos de NovaDreams — guía de puesta en marcha

Esta carpeta (`/pagos`) contiene una implementación nueva y autocontenida del
checkout: **tarjeta + Google Pay + Apple Pay vía Stripe**, **PayPal**, y un
hueco ya cableado (pero apagado) para **Amazon Pay**. No depende de Node,
build tools ni Composer — solo HTML/CSS/JS por un lado y PHP plano por otro,
para que encaje en un hosting compartido tipo Hostinger.

> ⚠️ Importante: no tuve acceso al código real que ya tenías en producción
> (la sesión donde se estaba trabajando no estaba disponible), así que esto
> **no es un parche sobre tus archivos existentes** — es una implementación
> de referencia, lista para revisar e integrar en tus páginas reales. Antes
> de sustituir nada en producción, compárala con lo que ya tienes.

## 1. Por qué probablemente fallaba Google Pay

Los motivos más comunes cuando alguien integra Google Pay "a pelo" (API de
Google directamente) y deja de funcionar:

1. **Dominio no verificado.** Los botones de wallet (Google Pay/Apple Pay)
   exigen que el dominio esté verificado ante el proveedor. Con Stripe, esto
   se hace en un solo sitio: **Stripe Dashboard → Configuración → Payment
   method domains** — tienes que añadir `novadreams.shop` ahí, si no, el
   botón no aparece o falla en silencio.
2. **HTTPS obligatorio**, incluso en pruebas.
3. **merchantId / gateway mal emparejados** entre Google Pay y tu procesador
   de pagos — si probabas Google Pay "directo" (no vía Stripe/PayPal), cada
   cambio de configuración en un lado sin el otro rompe el botón.
4. **Entorno TEST vs PRODUCTION** mezclados (claves de test con configuración
   de producción, o al revés).

Esta implementación evita el punto 3 usando el **Payment Request Button** de
Stripe: un único componente que internamente decide si mostrar Google Pay o
Apple Pay según el navegador/dispositivo del comprador, usando la misma
integración y las mismas claves de Stripe que ya usas para tarjeta. Menos
piezas sueltas = menos sitios donde puede romperse.

## 2. Puesta en marcha

1. Copia `pagos/api/config.example.php` → `pagos/api/config.php` (este
   segundo NO se sube a git, ya está en `.gitignore`).
2. Rellena las claves:
   - **Stripe**: <https://dashboard.stripe.com/apikeys> (empieza con las de
     modo *test*, `sk_test_...` / `pk_test_...`).
   - **PayPal**: <https://developer.paypal.com/dashboard/applications> — crea
     una app REST, copia `Client ID` y `Secret`. Deja `environment: sandbox`
     hasta que hayas probado un pago de verdad.
   - **Amazon Pay**: déjalo vacío por ahora (ver sección 5).
3. Sube la carpeta `/pagos` a tu hosting (Hostinger) tal cual, respetando la
   estructura de carpetas.
4. Confirma que PHP y cURL están activos en tu hosting (lo están por defecto
   en Hostinger compartido).
5. Abre `https://novadreams.shop/pagos/checkout.html` y prueba.

### Verificación de dominio para las wallets (Stripe)

En **Stripe Dashboard → Configuración → Payment method domains**, añade
`novadreams.shop` (y el subdominio que uses si es distinto). Sin este paso,
`paymentRequest.canMakePayment()` devuelve `null` y el botón de Google
Pay/Apple Pay se queda oculto aunque todo lo demás esté bien.

## 3. Probar sin cobrar de verdad

- **Stripe** (modo test): tarjeta `4242 4242 4242 4242`, cualquier fecha
  futura, cualquier CVC. Lista completa de tarjetas de prueba:
  <https://docs.stripe.com/testing>.
- **Google Pay / Apple Pay**: con las claves de Stripe en modo test, el botón
  de wallet solo aparece si el navegador/dispositivo lo soporta:
  - Google Pay: Chrome en Android, o Chrome de escritorio con una tarjeta
    guardada en la cuenta de Google.
  - Apple Pay: Safari en iPhone/iPad/Mac con una tarjeta en Wallet.
- **PayPal**: con `environment: sandbox`, usa una cuenta de comprador de
  prueba (se generan automáticamente en tu cuenta de developer de PayPal, en
  *Sandbox → Accounts*).

## 4. Pasar a producción

1. Cambia las claves de Stripe a las de modo **live** (`sk_live_` /
   `pk_live_`).
2. Cambia `paypal.environment` a `live` y usa las claves de tu app de PayPal
   en modo producción (o crea una nueva app en modo live).
3. Repite la verificación de dominio en Stripe si no la hiciste ya.
4. Haz una compra real de importe mínimo para confirmar que el dinero llega.

## 5. Amazon Pay (pendiente)

Amazon Pay necesita una **cuenta de comerciante aprobada por Amazon** antes
de poder integrarlo — no es solo pegar una clave pública como con PayPal.
Pasos:

1. Solicítala en <https://sellercentral.amazon.com> → Amazon Pay Integration
   Central.
2. Cuando te den `merchant_id`, `public_key_id` y `store_id`, rellénalos en
   `pagos/api/config.php`.
3. Habrá que añadir un endpoint `api/amazonpay-create-session.php` que firme
   la sesión de checkout (Amazon Pay no funciona solo con un client-id
   público en el navegador, a diferencia de PayPal) y cargar su SDK
   (`https://static-eu.payments-amazon.com/checkout.js`) en `checkout.html`.
   `checkout.js` ya tiene el hueco preparado (`initAmazonPay`) — dime cuando
   tengas las credenciales y lo completo.

## 6. Seguridad — no te saltes esto

- `api/config.php` **nunca** debe subirse a git ni quedar accesible
  públicamente con las claves en texto plano fuera de esa carpeta protegida.
- El importe que se cobra siempre se debe recalcular/validar en el servidor
  (los `TODO` en `paypal-create-order.php` y `create-payment-intent.php`
  marcan dónde) — nunca te fíes de un importe que llega tal cual desde el
  navegador.
- `paypal-capture-order.php` tiene un `TODO` para marcar el pedido como
  pagado en tu base de datos antes de dar la compra por buena.
