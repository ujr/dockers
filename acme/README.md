# Docker image for an ACME client

Goal: minimalistic Docker image for a minimalistic ACME client
to automatically manage free HTTPS certificates.

## Background

- HTTPS is HTTP over TLS/SSL (secure HTTP)
- for HTTPS you need a server certificate
- free certificates: try <https://zerossl.com>
  or <https://letsencrypt.org>
- certificate renewal can be automated using ACME
- ACME = [RFC8555][] = Automatic Certificate Management Environment
- ACME is a protocol, many clients exist
- [Certbot][] by [EFF][] is probably the best known ACME client
- [bacme][] is a small half-automatic implementation in Bash
- [uacme][] is a small C implementation, has Alpine package
- How about **localhost?** Use a self-signed certifcate

[RFC8555]: https://tools.ietf.org/html/rfc8555
[Certbot]: https://certbot.eff.org/
[EFF]: https://www.eff.org/
[bacme]: https://gitlab.com/sinclair2/bacme
[uacme]: https://github.com/ndilieto/uacme/
