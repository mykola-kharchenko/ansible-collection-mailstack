# mykola_kharchenko.mailstack — bootc image build (day-1)
#
# Build:
#   podman build -t localhost/mailstack-bootc .
# Switch a running host onto it:
#   bootc switch --transport registry <your-registry>/mailstack-bootc
#
# For RHEL, override BASE_IMAGE and build with an entitled host / pull secret:
#   podman build --build-arg BASE_IMAGE=registry.redhat.io/rhel10/rhel-bootc:10.2 .
ARG BASE_IMAGE=quay.io/fedora/fedora-bootc:42
FROM ${BASE_IMAGE}

# Build-time-only tooling. ansible-core and the collection are removed again in
# the same layer chain so they never ship in the final image.
COPY . /src

RUN dnf -y install ansible-core \
    && ansible-galaxy collection build /src --output-path /tmp/collection \
    && ansible-galaxy collection install /tmp/collection/mykola_kharchenko-mailstack-*.tar.gz \
         -p /usr/share/ansible/collections \
    && ansible-galaxy collection install -r /src/requirements.yml \
         -p /usr/share/ansible/collections \
    && ansible-playbook -i localhost, -c local \
         mykola_kharchenko.mailstack.build \
    && dnf -y remove ansible-core \
    && dnf clean all \
    && rm -rf /src /tmp/collection /root/.ansible

# Validate the image meets bootc container requirements.
RUN bootc container lint
