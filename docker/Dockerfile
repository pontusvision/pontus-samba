FROM centos/systemd AS builder
COPY ./build-local.sh ./build-local.sh
RUN ./build-local.sh
COPY ./create-keys.sh ./create-keys.sh
RUN ./create-keys.sh
RUN useradd -ms /bin/bash pontus
RUN /opt/pontus/pontus-samba/current/config-samba.sh

FROM centos:7
MAINTAINER Leo Martins lmartins@pontusnetworks.com
EXPOSE 389
EXPOSE 686

RUN  yum -y install epel-release && yum -y update  && yum clean all && rm -rf /var/cache/yum
RUN  yum -y install gnutls
COPY --from=builder /opt/pontus  /opt/pontus
COPY --from=builder /etc/krb5.conf  /etc/krb5.conf
COPY --from=builder /etc/pki  /etc/pki

#RUN useradd -ms /bin/bash pontus && chown -R pontus: /opt/pontus
#USER pontus
CMD /opt/pontus/pontus-samba/current/sbin/samba -F

