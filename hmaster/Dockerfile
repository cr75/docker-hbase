FROM cr75/us.tlm.nutch:hbase-base
MAINTAINER Kevin Carter <kevin@tlm.us>

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 16000 16010

CMD ["/run.sh"]
