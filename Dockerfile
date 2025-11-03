FROM odoo:18.0

USER root

# (Opcional) instala libs Python del módulo en una ruta aislada
RUN mkdir -p /opt/qiflibs /opt/odoo/custom-addons
COPY requirements.txt /opt/odoo/requirements.txt
RUN if [ -s /opt/odoo/requirements.txt ]; then \
      pip3 install --no-cache-dir --target=/opt/qiflibs -r /opt/odoo/requirements.txt ; \
    fi
ENV PYTHONPATH="/opt/qiflibs:$PYTHONPATH"

# Copia tus addons
COPY addons/ /opt/odoo/custom-addons/

USER odoo

# Arranque con proxy y rutas de addons (oficial + tus custom)
CMD ["odoo",
     "--proxy-mode",
     "--http-port=8069",
     "--gevent-port=8072",
     "--addons-path=/usr/lib/python3/dist-packages/odoo/addons,/opt/odoo/custom-addons"]
