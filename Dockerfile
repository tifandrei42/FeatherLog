# Multi-stage build for the FeatherLog *web* build.
#
# NOTE: This containerizes the Flutter **web** target for a shareable demo /
# DevOps showcase. The shipping product is the Android APK (built via the
# release workflow) — a container cannot run a native Android/iOS app.
#
# Stage 1 compiles the web bundle with the Flutter SDK; stage 2 serves the
# static output from a tiny nginx image (the final image carries no SDK).

# ---- Stage 1: build ----
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app

# Copy only the manifests first so `pub get` is cached unless deps change.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source and build the release web bundle.
COPY . .
RUN flutter build web --release

# ---- Stage 2: serve ----
FROM nginx:1.27-alpine AS runtime

# SPA-aware config (history routing + sensible caching).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Static site produced by stage 1.
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

# Simple liveness check used by compose / orchestrators.
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --spider -q http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
