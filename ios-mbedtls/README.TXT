mbedtls for iOS
===============

This project will build mbedtls (formerly known as PolarSSL) for iOS.

Project page: https://tls.mbed.org/

Select target "UniversalLib" and build. You may find that Xcode refuses to build the
library unless you plug in a physical device rather than use the Simulator.

The output is a static library with support for architectures armv7, armv7s, arm64,
i386 and x86_64, plus LLVM IR (bitcode).

Ensure that you build for the "Release" scheme ("Product->Scheme->Edit Scheme")

Deployment target is iOS 8+

To use in a client app, import all header files from the "include" directory and drag
libmbedtls.a into the project.

Note: the source code has been customized. It exports an additional function named
'mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block' which allows access to the
last parsed certificate's public key (required for implementing SSL pinning).
