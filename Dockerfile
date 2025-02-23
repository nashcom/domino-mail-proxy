############################################################################
# Copyright Nash!Com, Daniel Nashed 2025 - APACHE 2.0 see LICENSE
############################################################################


ARG BASE_IMAGE=alpine
ARG NGINX_VER=$NGINX_VER
FROM $BASE_IMAGE

ARG NGINX_VER=$NGINX_VER

USER root

COPY compile.sh /  
COPY nginx_template.conf /
COPY entrypoint.sh /

RUN /compile.sh

FROM $BASE_IMAGE

USER root

COPY --from=0 /usr/bin/nginx /usr/bin/nginx
COPY --from=0 /entrypoint.sh / 
COPY --from=0 /nginx_template.conf /nginx_template.conf

COPY install.sh /  
RUN /install.sh && \
  rm -f /install


# Expose Ports HTTPS
EXPOSE 25 465 993 995 

ENTRYPOINT ["/entrypoint.sh"]

USER 1000
