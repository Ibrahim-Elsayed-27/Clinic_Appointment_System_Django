ARG WEB_IMAGE

FROM ${WEB_IMAGE} AS source

FROM nginx:alpine

COPY --from=source /app/staticfiles /app/staticfiles
COPY nginx.conf /etc/nginx/conf.d/default.conf