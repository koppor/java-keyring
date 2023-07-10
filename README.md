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

How much protection keychain items actually get depends a lot on what OS is being used, how your 
app is packaged and other specific circumstances of your situation.

The ideal scenario is that items stored in the keychain are protected from other applications that
might be malware. This is achievable sometimes but requires care.

### macOS

The macOS keychain by default restricts keychain items so they are readable only by the application 
that created them. This is a useful security feature that makes storing things in the keychain worthwhile 
on this platform. However, to be secure your app must meet several criteria:

1. It must be packaged as a Mac app bundle with an included JVM. If you run your app using a shared JDK
   install (`java -jar ...`) then the app identity put into the keychain item's access control list will
   be the JDK itself, and thus anything can read the items by simply executing a JAR that prints out
   the stored credential. Thus you would get no additional security over a regular file.
3. The app must be signed using an Apple Developer ID certificate. Unsigned apps can be easily tampered
   with, so there's no protection for those.
4. The app must not be signed with the `get-task-allow` entitlement. Apps marked this way allow debuggers
   to attach to them, meaning code can be injected into your process and the credential stolen that way.
   Note that notarization fails if you use this entitlement, so if you pass notarization then this isn't
   a concern.
5. Your app must not allow code injection in other ways e.g. via environment variables or downloaded
   plugin JARs (unless plugins are themselves protected by signing).

Additionally the user must be running macOS Ventura or higher. This is the first OS version that stops 
apps tampering with each other's files by default, regardless of whether an app is sandboxed or not.
(See Settings.app > Security & Privacy > {App Management, Full Disk Access} for the relevant permissions).

When all criteria are met credentials can be worked with in a theoretically secure manner, and they are
also secure against physical attacks thanks to the dedicated security chip that's available in all Macs 
with a touch bar or that use Apple Silicon. Other apps that try to access the credentials will trigger
a permissions prompt that lets the user grant or deny access.

Unfortunately, although it may appear that the `jpackage` tool can be used to meet these criteria, it
fails (4) as it doesn't fully lock down the bundled JVM against code injection. 

A simple way to meet all criteria is to use [Conveyor](https://hydraulic.dev/), which is an 
alternative to `jpackage`. It has the advantage that it can package, sign and notarize Mac apps from 
any platform, so you can ship apps that use java-keyring securely even if you don't have a Mac yourself. 
It's careful to configure the JVM to prevent code injection attacks. Conveyor also supplies a useful 
`conveyor run` command that packages and then immediately executes your app in bundle context, so if 
you do have a Mac then you can iterate quickly and see that it's working. Finally it has other security 
advantages too, for example, apps will auto update. Check the access control list in the Keychain Access 
app to see which apps can access your stored credentials.

### Windows

Windows can protect credentials from other apps executed by the user, but only in a very specific set
of circumstances. In any other situation credentials can be read by any app you run even if not 
elevated, and therefore the system key chain offers no additional security beyond ordinary user file
security.

To protect credentials against attack on this platform, the following criteria must be met:

1. Your application must bundle its own JVM and be packaged using the [MSIX](https://learn.microsoft.com/en-us/windows/msix/overview)
   format. Apps distributed using installers like NSIS or using the deprecated MSI package format
   will get no protection. This is because Windows can't determine which files belong to which
   application when these install mechanisms are used; they don't get "package identity".
   When an app is packaged with the newer MSIX format the install is handled by Windows itself.
   As part of the install process Windows creates what can be thought of as a new user account
   (security context/SID), which the app will run as automatically when launched. Additionally
   the installed files are locked down against modification, even by admin-elevated processes.
3. The application's MSIX package must be signed. Self-signing can work however, as long as the
   apps's self-signing certificate is installed to the system and marked as trusted.
4. The application must be locked down against code injection attacks.
5. A malicious application trying to steal the credential must have debug privileges. Debug
   privileges become available if (a) the user is an administrator and runs the attacking
   program with administrator access, or (b) the user has been granted debug privileges by default.
   On managed Windows networks whether a user can start a debugger is determined by their IT
   admins ([here is a useful guide to auditing and controlling `SeDebugPrivilege`](https://blog.palantir.com/windows-privilege-abuse-auditing-detection-and-defense-3078a403d74e)).
6. Blocking physical attacks requires [Windows Defender Credential Guard](https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/credential-guard).
   This feature is currently only available in the Enterprise or Education editions of Windows.
   When Credential Guard is activated the credentials are stored and loaded by a dedicated
   virtual machine running on top of the Windows Hypervisor, thus storage is protected even
   against processes with administrator access (although the program that works with the credentials
   won't be). Additionally the secure boot feature and TPM chip can be used to encrypt storage
   such that it can't be read except by that specific machine, blocking offline attacks.
   Without Credential Guard credentials are simply stored in a regular file on disk, encrypted under
   a key derived from the user's password. Therefore anything that can obtain this file can probably
   brute force the password and thus obtain the stored credentials. The file is however not
   accessible to regular users and thus requires administrator access, or physical access to the
   machine's storage.

Unfortunately, although it may appear that the `jpackage` tool can be used to meet these criteria, 
it fails (1) and therefore (2). `jpackage` packages apps using MSI or NSIS, not MSIX. Therefore 
your app won't be granted its own dedicated user SID, its installed files won't be tamper-proofed 
and thus stored credentials will be available to any program the user runs. Additionally, jpackage 
doesn't block code injection into the JVM thus also failing (3).

A simple way to meet all criteria is to use [Conveyor](https://hydraulic.dev/), which is an 
alternative to `jpackage`. It can create and sign MSIX packages from any OS, meaning you can ship
apps that use the keychain securely even if you don't have Windows (e.g. from Linux CI workers).
Therefore apps deployed this way satisfy (1) and (2). It also locks down the JVM against code 
injection satisfying (3). It has other security advantages too, for example, apps will auto update.
Finally, if you want to self-sign your app it can produce an installer EXE that first installs your
self-generated certificate (requiring admin elevation), then installs the MSIX. Therefore getting 
protection is possible even if you self-sign, as long as all your users have admin rights to do the
install with. Please note that if you run your app with `conveyor run` or if users run the 
app using the generated zip file and not the MSIX, then package identity won't be present and keychain 
items will be stored as your regular Windows user i.e. insecurely.

### Linux

Linux key ring implementations offer no additional security beyond ordinary UNIX user security once
unlocked. See [CVE-2018-19358](https://www.cve.org/CVERecord?id=CVE-2018-19358) for details.
According to [Debian's evaluation](https://security-tracker.debian.org/tracker/CVE-2018-19358), this 
is by design. Workaround: Users can use separate key rings. However once they unlock the keyring
the credentials can still be taken by any code that happens to be running.

I personally wouldn't store any credentials in the system keyring, ever.
 
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
