FROM nginx:1.25.2

COPY configs /configs

COPY entrypoint.sh /entrypoint.sh

CMD /entrypoint.sh
