# ------ COMPILER - STAGE ------------
FROM quay.io/almalinuxorg/10-minimal AS compiler

# Install core tools and SaltStack
RUN echo " Update OS repos"  && \
    microdnf update -y && \
    microdnf upgrade -y && \
    echo "Cleanup OS Packages" && \
    rm -rf /var/cache/dnf* && \
    rm -rf /usr/share/doc* && \
    microdnf clean all
#--- Ready for Custom Installation

# Build-only toolchain, discarded after this stage
RUN microdnf -y install gcc make patch bzip2 gzip autoconf automake libtool bison \
    readline-devel zlib-devel libffi-devel openssl-devel tar \
    && microdnf clean all

# Build and install libyaml from source into an isolated prefix
WORKDIR /tmp
RUN curl -O https://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz \
    && tar -xzf yaml-0.2.5.tar.gz \
    && cd yaml-0.2.5 \
    && ./configure --prefix=/opt/libyaml && make -j$(nproc) && make install \
    && cd .. && rm -rf yaml-0.2.5*

# ------ Runtime - Stage ----
FROM quay.io/almalinuxorg/10-minimal

LABEL maintainer="rauf.hammad@gmail.com"
LABEL description="Reusable Salt Minion base image"

# Update OS Image
RUN echo " Update OS repos"  && \
    microdnf update -y && \
    microdnf upgrade -y && \
    echo "Cleanup OS Packages" && \
    rm -rf /var/cache/dnf* && \
    rm -rf /usr/share/doc* && \
    microdnf clean all
#--- Ready for Custom Installation

# Install core tools and SaltStack (runtime packages only, no build toolchain)
RUN microdnf -y install procps net-tools curl nano httpd openssh-server \
      dnf \
    && curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo \
      | tee /etc/yum.repos.d/salt.repo \
    && microdnf update -y \
    && microdnf -y install salt-minion cronie \
    && microdnf clean all \
    && rm -rf /var/cache/dnf* /usr/share/doc*

# Bring in libyaml compiled in the builder stage
COPY --from=compiler /opt/libyaml /usr/local
RUN ldconfig

WORKDIR /root

# Enable services
RUN systemctl enable httpd \
    && systemctl enable sshd \
    && systemctl enable salt-minion

# Configure Salt-Minion OS() Specific Providers
RUN printf '%s\n' \
      'providers:' \
      '  pkg: dnf' \
      '  service: systemd' \
      >> /etc/salt/minion

# Configure Salt minion to point to local master
RUN echo "master: localhost" > /etc/salt/minion.d/master.conf \
    && echo "saltm-instance" > /etc/salt/minion_id

RUN echo 'export PATH=$PATH:/opt/salt' >> /root/.bashrc

# Allow SSH key login for root
RUN mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh \
    && touch /root/.ssh/authorized_keys \
    && chmod 600 /root/.ssh/authorized_keys \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

RUN [ -n "$SSH_PUB_KEY" ] && echo "$SSH_PUB_KEY" >> /root/.ssh/authorized_keys || echo "No SSH key provided"

# Set root password
RUN echo "root:minion!" | chpasswd

# Expose ports and volume
VOLUME [ "/etc/salt/minion.d" ]
EXPOSE 22

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]