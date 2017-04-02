FROM nginx

COPY ./index.html /usr/share/nginx/html
COPY ./healthz.html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf

EXPOSE 80/tcp
CMD sed -i "s/STATUS_HOST/$STATUS_HOST/g" /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
