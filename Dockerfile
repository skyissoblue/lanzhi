FROM nginx:1.27-alpine AS prebuilt
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html

FROM ghcr.io/cirruslabs/flutter:3.44.0 AS flutter-build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
ARG API_BASE_URL=""
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine AS built
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=flutter-build /app/build/web /usr/share/nginx/html
EXPOSE 80
