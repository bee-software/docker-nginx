FROM nginx:1.13.5

COPY entrypoint.sh /entrypoint.sh

CMD /entrypoint.sh