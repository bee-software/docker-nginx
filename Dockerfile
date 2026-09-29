FROM nginx:1.31.6

COPY configs /configs

COPY entrypoint.sh /entrypoint.sh

CMD /entrypoint.sh
