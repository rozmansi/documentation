# Introduction
Both Fedora (20) and CentOS >= 6.6 are supported. CentOS 7.0 is not yet 
supported due to missing `mod_auth_mellon` support that will most likely come 
in the 7.1 release, it was added to CentOS 6.6 only.

It is highly recommended to use at least three (virtual) machines to run this.

1. the `vpn-cert-service` machine handling the signing/configuration management
   an revocation. The web service MUST only available to the other two machines
2. the `vpn-user-portal` machine handling the user interaction. It MUST have
   access to the `vpn-cert-service` and have a password to use the API
3. the OpenVPN machine handling the VPN connections. It does not need to have a 
   connection to `vpn-user-portal` machine, and only needs read access to the 
   `ca.crl` URL on the `vpn-cert-service` machine. It does not need a password
   to access the API

For testing purposes of course this can be deployed on one machine. But for
production you MUST use at least three machines with sufficient security in 
place to avoid unauthorized access.

# Docker
See `docker` directory.

# Repositories
For CentOS 6 you will need to enable 
[EPEL](https://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F) 
and [CR](https://wiki.centos.org/AdditionalResources/Repositories/CR). The CR
repository is needed because CentOS 6.6 is not yet available at this time, and
it is the first version to include `mod_auth_mellon`. CentOS 7.1 should also 
be sufficient once released.

For Fedora >= 20 you will not need to enable any additional repositories.

# Packages
The software is contained in two projects:

- [vpn-user-portal](https://github.com/fkooman/vpn-user-portal)
- [vpn-cert-service](https://github.com/fkooman/vpn-cert-service)

The component `vpn-user-portal` is the UI for the end user, protected by SAML 
(using `mod_mellon`). It interacts with `vpn-cert-service` using a HTTP API 
protected by basic authentication.

The `vpn-cert-service` component is responsible for all the 'low level' 
configuration handling like running the CA, generating certificates, generating 
configurations, handling revocations and maintaining the CRL.

These components depend on the following PHP libraries that are not available
in EPEL or the base repository:

- [php-lib-rest](https://github.com/fkooman/php-lib-rest)
- [php-lib-rest-plugin-basic](https://github.com/fkooman/php-lib-rest-plugin-basic)
- [php-lib-rest-plugin-mellon](https://github.com/fkooman/php-lib-rest-plugin-mellon)
- [php-lib-ini](https://github.com/fkooman/php-lib-ini)
- [php-lib-json](https://github.com/fkooman/php-lib-json)

These libraries are also all packaged as RPMs. All required files for 
generating the RPMs are available in the project directories under the `rpm` 
directory in their respective repository.

# Installation
You can regenerate the RPMs yourself from source using the files in the `rpm`
directory of this project. On a development machine you can do the following:

    $ sudo yum install rpmdevtools createrepo
    $ rpmdev-setuptree

    $ cd rpm
    $ sh ./build_all.sh

This should create the RPMs in `${HOME}/rpmbuild/RPMS`, ready for install using
`yum`. See `build_all.sh` source for more information and an `rsync` example to
copy the whole repository to a web server.

If you want to create a `yum` configuration file you can put the following in 
`/etc/yum.repos.d/eduVPN.repo`:

    [eduVPN]
    name=Packages for eduVPN and its dependencies
    baseurl=http://localhost/eduVPN/RPMS
    enabled=1
    gpgcheck=0

Of course, for production environments you SHOULD use `https` and SHOULD sign
the RPMs you generate on your trusted development machine or have some other
secure way to deploy the packages.

# Configuration
Both `vpn-cert-service` and `vpn-user-portal` will have a working configuration
file on installation. But you SHOULD update the configuration files in 
`/etc/vpn-user-portal` and `/etc/vpn-cert-service` to suit your environment if
needed.

You then need to run the database initialization scripts:

    $ sudo -u apache vpn-cert-service-init
    $ sudo -u apache vpn-user-portal-init

Do not forget to update the passwords and Apache configuration of both 
`vpn-cert-service` and `vpn-user-portal`. To generate a password hash you can 
use this:

    $ vpn-cert-service-generate-password-hash mySecretPass

You can add the hash to `/etc/vpn-cert-service/config.ini` and the plain text
value to `/etc/vpn-user-portal/config.ini`.

# SAML configuration
Using the Apache module `mod_auth_mellon`. See 
[php-lib-rest-plugin-mellon](https://github.com/fkooman/php-lib-rest-plugin-mellon) 
documentation for more information on how to configure `mod_auth_mellon`.

# Server configuration
You can now generate a OpenVPN server configuration on the `vpn-cert-service` 
machine and copy that to OpenVPN machine:

    $ sudo -u apache vpn-cert-service-generate-server-config

Copy/paste the output and place it in `/etc/openvpn/server.conf` on your 
OpenVPN server.

## CRL
The make the CRL work, a 'cronjob' is needed to occasionally retrieve the CRL
from `vpn-cert-service` using the following command:

    # wget -q -N https://example.org/vpn-cert-service/api.php/ca.crl -O /etc/openvpn/ca.crl

Run this as often as you want. Probably every hour is enough. You SHOULD use 
`https` and of course change the domain name to your own server.

Modify the `/etc/openvpn/server.conf` file to use the CRL.

**NOTE: current connections will not be terminated if the certificate is added to the CRL, only new connections will be denied**.
