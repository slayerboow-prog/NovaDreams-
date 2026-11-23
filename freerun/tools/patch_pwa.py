#!/usr/bin/env python3
"""Ajusta el service worker de la exportación web de Godot para que cada versión nueva
llegue sola al móvil (iPhone/Android), también con el juego añadido a la pantalla de inicio.

El service worker original sirve primero lo guardado en caché y la versión nueva no se
activa hasta cerrar del todo la app (en iOS casi nunca ocurre). Con este parche:
  - la versión nueva se activa al instante (skipWaiting + clients.claim),
  - el juego se pide primero a la red y la caché solo se usa sin conexión.
Uso: python3 tools/patch_pwa.py export/web/index.service.worker.js
"""
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

def sub(old: str, new: str) -> None:
    global src
    if old not in src:
        sys.exit("patch_pwa: no se encontró el fragmento esperado:\n" + old)
    src = src.replace(old, new, 1)

sub("event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));",
    "self.skipWaiting();\n\tevent.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));")
sub("self.addEventListener('activate', (event) => {\n\tevent.waitUntil(caches.keys().then(",
    "self.addEventListener('activate', (event) => {\n\tevent.waitUntil(self.clients.claim());\n\tevent.waitUntil(caches.keys().then(")
sub("""				let cached = await cache.match(event.request);
				if (cached != null) {""", """				// Red primero: siempre la última versión; la caché solo sin conexión.
				try {
					return await fetchAndCache(event, cache, isCacheable);
				} catch (e) {
					console.warn('Sin red, usando caché: ', e); // eslint-disable-line no-console
				}
				let cached = await cache.match(event.request);
				if (cached != null) {""")
# Revalidar con el servidor (ETag) en lugar de usar la caché HTTP de 10 minutos de GitHub Pages
sub("response = await self.fetch(event.request);",
    "response = await self.fetch(event.request.mode === 'navigate' ? event.request : new Request(event.request, { cache: 'no-cache' }));")
open(path, "w", encoding="utf-8").write(src)
print("patch_pwa: service worker actualizado (" + path + ")")
