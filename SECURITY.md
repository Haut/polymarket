# Security Policy

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

**Please do not report security vulnerabilities through public GitHub issues.**

### How to Report

1. Email your findings to **rkhaut1@gmail.com**
2. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt within 48 hours
- **Updates**: We will provide status updates as we investigate
- **Resolution**: We aim to resolve critical issues as quickly as possible
- **Credit**: We will credit reporters in our release notes (unless you prefer anonymity)

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |

## Security Best Practices

When using this library:

- Keep dependencies up to date
- Never commit API keys or secrets to version control
- Use environment variables for sensitive configuration
- Enable TLS for all API communications
- Review and validate all inputs from external sources

## Scope

The following are in scope for security reports:

- Authentication/authorization flaws
- Data exposure vulnerabilities
- Injection vulnerabilities
- Cryptographic issues
- Dependencies with known vulnerabilities

## Acknowledgments

We appreciate the security research community's efforts in helping keep this project secure.
