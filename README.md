# RHSSO with SSL enabled

## Overview: 

This provides an example of how to enable ssl for RHSSO utilizing the provided templetes in its current release 7.4 fully supported solution coming in a future release 7.5. This is for example use only.

**Steps**

1. Create a RHSSO custom image with ssl enabled parameter for the jdbc driver
   * Create a batch script utilizing jboss to enable the parameter ssl=verify-ca see sso-extenstion.cli for reference
   * Create a docker file to build the image new image layered on top of the current RHSSO image for 7.4 see dockerfile for reference
   * Create the new image
     * docker build -t quay.io/matrujil/rhsso-ssl:3.3 .
   * Push the docker image to a container registry that you can pull the image from. For our purposes we will use quay.io
     * docker push quay.io/matrujil/rhsso-ssl:3.3 
2. Create the config map for public ssl cert needed to connect to the database on the RHSSO application
   * Created public-cert-sso config map which contained the ssl public cert
3. Create the config map and secret needed for enablement of ssl on the postgres database
   * Create a config map to enable ssl in the postgresql configuration file. For our example will call it psql-config, this should include the following
   ```
   ssl = on
   ssl_cert_file = '/opt/app-root/src/certificate/tls.crt'
   ssl_key_file = '/opt/app-root/src/certificate/tls.key'
   ```
   * Create the secret for the ssl cert and key needed for the ssl setup on the postgresql database. For this example we will create secret ssl-cert that houses the cert and key
4. Create HTTPS and JGroups Keystores, and Truststore for RHSSO
   * Follow the documented process [here](https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.3/html-single/red_hat_single_sign-on_for_openshift/index#Configuring-Keystores)
5. Create the postgresql database from the template in your openshift project. Pass in the needed variables
   ```
   oc new-app --name=postgresql --template=postgresql-persistent -p POSTGRESQL_USER=user -p POSTGRESQL_PASSWORD=pass
   ```
6. Create the RHSSO application from the image we created earlier
   ```
   oc new-app --docker-image="quay.io/matrujil/rhsso-ssl:3.3” \
   -e DB_SERVICE_PREFIX_MAPPING=postgresql=DB \
   -e DB_JNDI='java:jboss/datasources/KeycloakDS' \
   -e DB_USERNAME=user \
   -e DB_PASSWORD=pass \
   -e DB_DATABASE=postgresql \
   -e TX_DATABASE_PREFIX_MAPPING=postgresql=DB \
   -e JGROUPS_PING_PROTOCOL=openshift.DNS_PING \
   -e X509_CA_BUNDLE='/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt' \
   -e JGROUPS_CLUSTER_PASSWORD=password \
   -e SSO_ADMIN_USERNAME=ssoAdmin \
   -e SSO_ADMIN_PASSWORD=RFBne5Go0VMT3c4DuE7XKKOOmE2l38Tn
   ```
7. Modify the deploymentConfigs to mount the config map and secret
   * First will need to implement on the database
   ```
   oc set volume dc/postgresql --add -t=configmap --configmap-name=psql-config --mount-path=/opt/app-root/src/postgresql-cfg

   oc set volume dc/postgresql --add -t=secret --secret-name=ssl-cert --default-mode=0600 --mount-path=/opt/app-root/src/certificate
   ```
   * Now implement on the RHSSO side
   ```
   oc set volume dc/rhsso-ssl --add -t=configmap --configmap-name=public-cert-sso --default-mode=0600 --mount-path=/opt/jboss/.postgresql

   ```
8. Confirm in the logs that a successful connection has occurred
9. Create a route for the RHSSO application and access the amdin console
   * oc expose svc/rhsso-ssl 




