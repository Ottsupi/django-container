# Django Container

## Features
* Django 5.2
* Postgres 17
* Gunicorn 23

## Learnings

### Setting up HTTPS for localhost
1. Generate key
    ``` bash
    openssl genrsa -out localhost.key 2048
    ```
2. Genarate cert
    ``` .conf
    # ssl.conf

    [req]
    distinguished_name = req_distinguished_name
    x509_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    C = 2-letter Country Code
    ST = State
    L = City
    O = Organization
    OU = Department
    CN = Common Name

    [v3_req]
    basicConstraints = critical,CA:true
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    keyUsage = critical, cRLSign, digitalSignature, keyCertSign
    extendedKeyUsage = serverAuth
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = localhost
    DNS.2 = 127.0.0.1
    ```
    ``` bash
    openssl req -x509 -nodes -days 1024 /
            -newkey rsa:2048 /
            -keyout localhost.key /
            -out localhost.crt /
            -config ssl.conf /
            -extensions 'v3_req'
    ```
3. Configure web server to use them
4. Add certificate to trust stores
5. Account for new requirements and fix them

### Troubleshooting localhost SSL errors
* If using containers, make sure port `443` is exposed
* `ERR_SSL_KEY_USAGE_INCOMPATIBLE` means that Key Usage must contain "Digital Signature, Certificate Signing, Off-line CRL Signing, CRL Signing (86)"
    * https://support.google.com/chrome/thread/239508594?hl=en&msgid=245153877
    * https://superuser.com/a/738644
    * https://stackoverflow.com/q/15123152
* Make sure to add certificate to trust stores
    * For windows:
        1. Run `certlm`
        2. Under Certificates - Local Computer, right click on Personal
        3. All tasks > Import...
        4. Import certificate
    * For chrome:
        1. Go to Settings > Privacy and Security > Security > Manage Certificates
        2. Local Certificates > Installed by you
        3. Import certificate
