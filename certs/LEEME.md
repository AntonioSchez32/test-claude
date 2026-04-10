# Generación de certificado SSL con OpenSSL (3 pasos)

Este documento describe de forma clara los tres pasos necesarios para generar una clave RSA de 4096 bits, crear un certificado autofirmado válido durante 365.000 días y verificar que contiene los Subject Alternative Names (SAN).  

Al final se incluye el fichero `san.cnf` utilizado.

> **Nota:** Es necesario tener instalado previamente OpenSSL y añadir la ruta a openssl.exe al PATH.

---

## 1. Generar clave RSA de 4096 bits (`key.pem`)

Opción recomendada (genpkey):

```bash
openssl genpkey -algorithm RSA -out key.pem -pkeyopt rsa_keygen_bits:4096
```

Opción alternativa:

```bash
openssl genrsa -out key.pem 4096
```

## 2. Genera el certificado autofirmado (cert.pem) válido 365.000 días

```bash
openssl req -x509 -new -nodes -key key.pem -sha256 -days 365000 -out cert.pem -config san.cnf -extensions v3_req
```

## 3. Verifica que el certificado contiene los SAN, busca la sección X509v3 Subject Alternative Name

```bash
openssl x509 -in cert.pem -noout -text
```

# Fichero san.cnf utilizado:

```ini
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
C  = ES
ST = Madrid
L  = Madrid
O  = Instituto Nacional de Estadística
OU = Herramienta de valoración para el proyecto Padron Online
CN = ine.es

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
# Dominios
DNS.1 = ine.es
DNS.2 = localhost

# IPs específicas
IP.1 = 127.0.0.1
IP.2 = 10.58.21.32
IP.3 = 10.58.21.17
IP.4 = 10.58.21.100
IP.5 = 10.59.178.21
```