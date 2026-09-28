/**
 * NovaDreams — checkout.js
 * Tarjeta + Google Pay + Apple Pay vía Stripe, PayPal vía PayPal Checkout,
 * y un hueco preparado (no activo todavía) para Amazon Pay.
 *
 * Nada de esto asume un backend con Node/build: los 3 endpoints que llama
 * (api/public-config.php, api/create-payment-intent.php, api/paypal-*.php)
 * son PHP plano, pensados para hosting compartido tipo Hostinger.
 *
 * Ver README-PAGOS.md para la puesta en marcha (claves, dominios, pruebas).
 */
(function () {
  "use strict";

  var API_BASE = "api/"; // ajusta si mueves la carpeta /pagos/

  function safe(fn) {
    return function () {
      try {
        return fn.apply(this, arguments);
      } catch (err) {
        console.error("[NovaDreams checkout]", err);
        setMessage("Ha ocurrido un error inesperado. Prueba de nuevo o usa otro método de pago.", "error");
      }
    };
  }

  function setMessage(text, state) {
    var el = document.getElementById("nd-checkout-message");
    if (!el) return;
    el.textContent = text || "";
    if (state) el.setAttribute("data-state", state);
    else el.removeAttribute("data-state");
  }

  function getCartTotal() {
    var el = document.getElementById("nd-total");
    return {
      amountCents: parseInt(el.getAttribute("data-amount-cents"), 10) || 0,
      currency: (el.getAttribute("data-currency") || "EUR").toUpperCase(),
    };
  }

  function postJSON(url, body) {
    return fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body || {}),
    }).then(function (res) {
      return res.json().then(function (data) {
        if (!res.ok) throw new Error(data.error || "Error de servidor");
        return data;
      });
    });
  }

  function getJSON(url) {
    return fetch(url).then(function (res) {
      return res.json().then(function (data) {
        if (!res.ok) throw new Error(data.error || "Error de servidor");
        return data;
      });
    });
  }

  // ---------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------
  document.addEventListener(
    "DOMContentLoaded",
    safe(function () {
      getJSON(API_BASE + "public-config.php").then(
        safe(function (publicConfig) {
          if (!publicConfig.stripePublishableKey || publicConfig.stripePublishableKey.indexOf("pk_") !== 0) {
            setMessage("Pagos no configurados todavía (falta api/config.php). Ver README-PAGOS.md.", "error");
            return;
          }
          initStripe(publicConfig);
          initPayPal(publicConfig);
          initAmazonPay(publicConfig);
        })
      );
    })
  );

  // ---------------------------------------------------------------------
  // Stripe: tarjeta + Payment Request Button (cubre Google Pay y Apple Pay)
  // ---------------------------------------------------------------------
  function initStripe(publicConfig) {
    if (typeof Stripe === "undefined") {
      setMessage("No se pudo cargar Stripe.js (¿bloqueado por un adblock o falla la red?).", "error");
      return;
    }

    var stripe = Stripe(publicConfig.stripePublishableKey);
    var elements = stripe.elements();
    var cart = getCartTotal();

    // -- Tarjeta --
    var cardElement = elements.create("card");
    cardElement.mount("#nd-card-element");

    var cardButton = document.getElementById("nd-card-submit");
    cardButton.addEventListener(
      "click",
      safe(function () {
        cardButton.disabled = true;
        setMessage("Procesando pago…");

        postJSON(API_BASE + "create-payment-intent.php", {
          amount_cents: cart.amountCents,
          currency: cart.currency,
        })
          .then(function (data) {
            return stripe.confirmCardPayment(data.clientSecret, {
              payment_method: { card: cardElement },
            });
          })
          .then(
            safe(function (result) {
              cardButton.disabled = false;
              if (result.error) {
                setMessage(result.error.message, "error");
              } else if (result.paymentIntent.status === "succeeded") {
                setMessage("¡Pago completado! Gracias por tu compra.", "success");
              }
            })
          )
          .catch(
            safe(function (err) {
              cardButton.disabled = false;
              setMessage(err.message, "error");
            })
          );
      })
    );

    // -- Payment Request Button: Google Pay / Apple Pay --
    // Stripe decide solo qué mostrar según navegador/dispositivo/wallets
    // configurados. Requiere: sitio servido en HTTPS, y el dominio registrado
    // en Stripe → Ajustes → "Payment method domains" (ver README-PAGOS.md,
    // es el paso que más se suele saltar y por lo que Google Pay "no sale").
    var paymentRequest = stripe.paymentRequest({
      country: "ES",
      currency: cart.currency.toLowerCase(),
      total: { label: "NovaDreams", amount: cart.amountCents },
      requestPayerName: true,
      requestPayerEmail: true,
    });

    var prButton = elements.create("paymentRequestButton", { paymentRequest: paymentRequest });

    paymentRequest.canMakePayment().then(
      safe(function (result) {
        if (result) {
          document.getElementById("nd-wallet-buttons").hidden = false;
          prButton.mount("#nd-payment-request-button");
        }
        // Si no hay wallet disponible en este dispositivo/navegador, el bloque
        // se queda oculto y el comprador simplemente usa tarjeta o PayPal.
      })
    );

    paymentRequest.on(
      "paymentmethod",
      safe(function (ev) {
        postJSON(API_BASE + "create-payment-intent.php", {
          amount_cents: cart.amountCents,
          currency: cart.currency,
        })
          .then(function (data) {
            return stripe.confirmCardPayment(
              data.clientSecret,
              { payment_method: ev.paymentMethod.id },
              { handleActions: false }
            );
          })
          .then(
            safe(function (confirmResult) {
              if (confirmResult.error) {
                ev.complete("fail");
                setMessage(confirmResult.error.message, "error");
                return;
              }
              ev.complete("success");
              if (confirmResult.paymentIntent.status === "requires_action") {
                // 3D Secure u otra verificación adicional.
                stripe.confirmCardPayment(data.clientSecret).then(
                  safe(function (final) {
                    if (final.error) {
                      setMessage(final.error.message, "error");
                    } else {
                      setMessage("¡Pago completado! Gracias por tu compra.", "success");
                    }
                  })
                );
              } else {
                setMessage("¡Pago completado! Gracias por tu compra.", "success");
              }
            })
          )
          .catch(
            safe(function (err) {
              ev.complete("fail");
              setMessage(err.message, "error");
            })
          );
      })
    );
  }

  // ---------------------------------------------------------------------
  // PayPal
  // ---------------------------------------------------------------------
  function initPayPal(publicConfig) {
    if (!publicConfig.paypalClientId) return; // no configurado todavía

    var script = document.createElement("script");
    var currency = getCartTotal().currency;
    script.src =
      "https://www.paypal.com/sdk/js?client-id=" +
      encodeURIComponent(publicConfig.paypalClientId) +
      "&currency=" +
      encodeURIComponent(currency);
    script.addEventListener(
      "load",
      safe(function () {
        window.paypal
          .Buttons({
            createOrder: function () {
              var cart = getCartTotal();
              return postJSON(API_BASE + "paypal-create-order.php", {
                amount: (cart.amountCents / 100).toFixed(2),
                currency: cart.currency,
              }).then(function (data) {
                return data.id;
              });
            },
            onApprove: function (data) {
              return postJSON(API_BASE + "paypal-capture-order.php", {
                orderID: data.orderID,
              }).then(
                safe(function () {
                  setMessage("¡Pago completado con PayPal! Gracias por tu compra.", "success");
                })
              );
            },
            onError: safe(function (err) {
              setMessage("Error con PayPal: " + err, "error");
            }),
          })
          .render("#nd-paypal-button-container");
      })
    );
    document.head.appendChild(script);
  }

  // ---------------------------------------------------------------------
  // Amazon Pay — preparado pero DESACTIVADO hasta tener cuenta de
  // comerciante aprobada. Amazon Pay firma cada sesión de checkout en el
  // servidor (no vale con solo un client id público como PayPal), así que
  // el endpoint api/amazonpay-create-session.php se añadirá cuando tengas
  // merchantId / publicKeyId / storeId reales. Ver README-PAGOS.md.
  // ---------------------------------------------------------------------
  function initAmazonPay(publicConfig) {
    var cfg = publicConfig.amazonPay || {};
    if (!cfg.merchantId || !cfg.publicKeyId || !cfg.storeId) {
      return; // sección se queda oculta (hidden en el HTML) hasta configurarlo
    }
    // Cuando tengas las credenciales:
    // 1) Carga el SDK de Amazon Pay:
    //    https://static-eu.payments-amazon.com/checkout.js
    // 2) Usa amazon.Pay.renderButton('#nd-amazonpay-button', {...})
    //    con un createCheckoutSessionConfig firmado por tu backend
    //    (api/amazonpay-create-session.php, pendiente de crear).
    // Documentación: https://amazon.com/payments/checkout
    document.getElementById("nd-amazonpay-section").hidden = false;
    setMessage("Amazon Pay: SDK pendiente de conectar (credenciales configuradas).", null);
  }
})();
