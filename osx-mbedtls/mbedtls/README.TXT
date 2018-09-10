mbedtls for Mac OS X
====================

This project will build mbedtls (formerly known as PolarSSL) for Mac OS X.

Project page: https://tls.mbed.org/

The output is a static library. Ensure that you build for the "Release" scheme
("Product->Scheme->Edit Scheme")

Deployment target is OS X 10.7 to match Safe Exam Browser version 2.1

To use in a client app, import all header files from the "include" directory and drag
libmbedtls.a into the project.

Note: the source code has been customized. It exports an additional function named
'mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block' which allows access to the
last parsed certificate's public key (required for implementing SSL pinning).
