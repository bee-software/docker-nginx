FROM nginx:1.13.5

COPY configs /configs

COPY entrypoint.sh /entrypoint.sh

CMD /entrypoint.sh
