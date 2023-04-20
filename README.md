## Status

[![Build Status](https://github.com/javakeyring/java-keyring/actions/workflows/ci.yml/badge.svg)](https://github.com/javakeyring/java-keyring/actions/workflows/ci.yml)
[![Maven Site](https://img.shields.io/badge/maven_site-1.0.1-green.svg)](https://javakeyring.github.io/java-keyring/1.0.1/)
[![Maven Central](https://maven-badges.herokuapp.com/maven-central/com.github.javakeyring/java-keyring/badge.svg)](https://maven-badges.herokuapp.com/maven-central/com.github.javakeyring/java-keyring)
[![codebeat badge](https://codebeat.co/badges/ebdaafc6-987c-41bd-8902-e277334aac30)](https://codebeat.co/projects/github-com-javakeyring-java-keyring-master)
[![codecov](https://codecov.io/gh/javakeyring/java-keyring/branch/master/graph/badge.svg)](https://codecov.io/gh/javakeyring/java-keyring)

## Summary

<img align="left" width="180" height="180" src="./src/site/resources/javakeyring.png">

java-keyring is a small library which provides a simple java API to store passwords and secrets __insecurely__ in native OS keystores.

Currently, Mac OS X, Windows and Linux (GNOME or KDE) are supported.

## History

Initially an abandoned bitbucket repo, but lotsa love has been given to it.

* Proper windows credential store access.
* Delete support.
* Solid testing.
* Automated builds in all target environments, though KWallet needs seeded with an existing wallet.

Initial repo: [https://bitbucket.org/east301/java-keyring](https://bitbucket.org/east301/java-keyring)

Cloned from: [https://bitbucket.org/bpsnervepoint/java-keyring](https://bitbucket.org/bpsnervepoint/java-keyring)

## Security Concerns

[CVE-2018-19358](https://www.cve.org/CVERecord?id=CVE-2018-19358) (Vulnerability)

On GNOME, after the key ring is unlocked, all applications of the current user can access the passwords.
According to [Debian's evaluation](https://security-tracker.debian.org/tracker/CVE-2018-19358), this is a non-issue.
Workaround: Users can use separate key rings.

Please keep in mind the above is not only about GNOME. Windows credentials [can be recovered easily](https://security.stackexchange.com/a/63909/37275).

Both Mac OS X and Windows will ask the runtime to allow the __Java runtime__ to connect to the key ring. This is an issue in case applications share the Java runtime: All of these applications can access the passwords stored in the key ring. This should be considered a vulnerability, as all java apps will be allowed access. I personally wouldn't store any credentials in the system keyring, ever, and especially on a system allowing any java application access.

That said, I would be comfortable storing in plain text. For example, passwords you may be forced to store in `~/.m2/settings.xml` are development databases credentials, etc.). For any of the things a developer usually has to store in plain text because there is no better option would be fine to store in the key ring. At least you can look them up in all your tests/apps in a single location if you are consistent with your service/user naming. Hopefully, these developing services are not available to the internet, you VPN into them, right? They may have attack vectors as well. [strongSwan](https://www.strongswan.org/) is pretty easy to set up.

Use a real password manager for your real secrets. Something like [KeePassXC](https://keepassxc.org/), [Bitwarden](https://bitwarden.com/), Enpass, 1Password, etc. Keep that password manager locked - make sure it is setup to autolock after you login to something with it. Use a secondary factor if you can with important services, particularly financial, and e-mail, and if you're in to that sort of thing, social sites - like github.com.

## Implementation

### Mac OS X

* Passwords are stored using [OS X Keychain](https://support.apple.com/guide/keychain-access/welcome/mac) using [Keychain Services](https://developer.apple.com/documentation/security/keychain_services/keychain_items). This is done either via built-in [JNA](https://github.com/twall/jna) bindings for the legacy API, or [jkeychain](https://github.com/davidafsilva/jkeychain).
  
### Linux/Freedesktop

* Passwords are stored using either [DBus Secret Service](https://specifications.freedesktop.org/secret-service/) (you've probably used [Seahorse](https://en.wikipedia.org/wiki/Seahorse_(software))) via the excellent [secret-service](https://github.com/swiesend/secret-service) library, or [KWallet](https://apps.kde.org/de/kwalletmanager5/) under KDE.

### Windows

* Passwords are stored using [Credential Manager](https://support.microsoft.com/en-us/help/4026814/windows-accessing-credential-manager), exceptions will contain [Error Codes](https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes). Access is via the [Wincred](https://docs.microsoft.com/en-us/windows/win32/api/wincred/) API.
* The Windows implementation of credentials lacks the concept of a session (built in to all other apis), as such, reads may not follow writes if another process deletes what was just written.   In practice this may not be a concern, though a PR adding a global lock for Windows or internal caching of passwords to simulate a session would likely be approved.

## Usage

The library is available at Maven central: <https://central.sonatype.com/artifact/com.github.javakeyring/java-keyring>.

The most simple usage is as follows:

```java
    try (Keyring keyring = Keyring.create()) {
      keyring.setPassword("domain", "account", "secret");
      String secret = keyring.getPassword("domain", "account");
      keyring.deletePassword("domain", "account");
    }
```

Recommend creating a dummy value if `getPassword()` fails, so that users know where to go set the value in their applications.

```java
    try (final Keyring keyring = Keyring.create()) {
      final String domain = "someDomain";
      final String account = "someAccount";
      try {
        return keyring.getPassword(domain, account);
      } catch ( PasswordAccessException ex ) {
        keyring.setPassword(domain, account, "ChangeMe");
        throw new RuntimeException("Please add the correct credentials to you keystore " 
            + keyring.getKeyringStorageType()
            + ". The credential is stored under '" + domain + "|" + account + "'"
            + "with a password that is currently 'ChangeMe'");
      }
    }
```

## Building

```bash
mvn clean install -Dgpg.skip=true
```

## License

Source code of java-keyring is available under a BSD license.
See the file [`LICENSE`](LICENSE) for more details.

## PRs are Welcome

Outstanding work:

* Windows error message conversion.
* Windows has no locking/session mechanism allowing for races between threads (like the maven tests in this project).
* Provide easy binding for Spring / CDI / etc.
* Perhaps optional UI requests for passwords (Wincred/secret-service have APIs at least to prompt users).
* Convert to Kotlin and test in different Kotlin build target (node/jvm/binary).

That said, this library is perfectly usable today and tested on all systems. Checkout the badges above!

## Special Thanks

java-keyring uses the following libraries, thanks a lot!

* [Java native access (JNA)](https://github.com/twall/jna)
* [Secret Service](https://github.com/swiesend/secret-service)
* [jkeychain](https://github.com/davidafsilva/jkeychain)
