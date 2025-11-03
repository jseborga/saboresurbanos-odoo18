FROM odoo:18.0

USER root
# Después (ignora fecha):
RUN set -eux; \
    apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update; \
    apt-get install -y --no-install-recommends \
        fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
        ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*

# Rutas para libs Python y addons
RUN mkdir -p /opt/qiflibs /opt/odoo/custom-addons

# Requisitos Python del/los módulos (si los hubiera)
COPY requirements.txt /opt/odoo/requirements.txt
RUN if [ -s /opt/odoo/requirements.txt ]; then \
      pip3 install --no-cache-dir --target=/opt/qiflibs -r /opt/odoo/requirements.txt ; \
    fi

# Instala qifparse (si luego no lo usas, puedes comentarlo)
RUN pip3 install --no-cache-dir --target=/opt/qiflibs qifparse

# Copia tus addons (incluye base_accounting_kit/)
COPY addons/ /opt/odoo/custom-addons/

# Que Python encuentre las libs extra
ENV PYTHONPATH="/opt/qiflibs:$PYTHONPATH"

# Permisos para el usuario odoo (UID 101 en la imagen oficial)
RUN chown -R odoo:odoo /opt/qiflibs /opt/odoo/custom-addons

EXPOSE 8069 8072
USER odoo

# Healthcheck interno (además del de EasyPanel)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD curl -fsS http://127.0.0.1:${ODOO_HTTP_PORT:-8069}/web/login || exit 1

# Arranque con variables (shell form = expande $ENV)
CMD odoo \
  --proxy-mode \
  --http-port=${ODOO_HTTP_PORT:-8069} \
  --gevent-port=${ODOO_GEVENT_PORT:-8072} \
  --db_host=${DB_HOST:-odoo-db} \
  --db_port=${DB_PORT:-5432} \
  --db_user=${DB_USER:-odoo} \
  --db_password=${DB_PASSWORD:-odoo} \
  --db_name=${DB_NAME:-postgres} \
  --admin-password=${ADMIN_PASSWORD:-admin} \
  --addons-path=/usr/lib/python3/dist-packages/odoo/addons,/opt/odoo/custom-addons
