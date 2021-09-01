FROM registry.redhat.io/rh-sso-7/sso74-openshift-rhel8:7.4

COPY sso-extensions.cli /opt/eap/extensions/
