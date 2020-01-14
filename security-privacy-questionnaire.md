# Security and Privacy Questionnaire

This document answers the [W3C Security and Privacy
Questionnaire](https://www.w3.org/TR/security-privacy-questionnaire/) for the
WebXR Hit Test Module specification.

**What information might this feature expose to Web sites or other parties,
and for what purposes is that exposure necessary?**

This feature will help a web site to map the user environment. Hit tests, in the
context of VR will only help map the 3D environment. However, in the context of
AR, it will help map the real world around the user.

Hit tests can be requested for a pre-defined ray which will allow the creation
of a reticle. This is a typical use case in AR. The other way to request a hit
test result is from user input like a tap on a phone screen.

**Is this specification exposing the minimum amount of information necessary to
power the feature?**

Yes. There isn't a lot of mitigations that can be done. This API does not allow
requesting a one shot hit test for a ray but only subscribing as there are
currently no use case for that and it would make aggressive mapping of the
environment slightly easier.

**How does this specification deal with personal information or
personally-identifiable information or information derived thereof?**

There are no direct PII exposed by this specification. The mapping of the user's
environment is the only derived information that could be done via this API.
Mitigations are mentioned below.

**How does this specification deal with sensitive information?**

The specification allows a user agent to restrict the usage of hit tests
subscriptions based on a XRRay. Using a lot of rays would allow the web site to
have a more detailed view of the environment and a user agent may decide that
after a certain number, the requests are being superfluous.

This feature of WebXR has to be listed when requesting an XR session which
allows the user agent to show a prompt specifically requesting user approval.

However, it's worth noting that a WebXR module will expose planes in the user
environment and another one meshes. These specifications will expose even
further details about the user environment than what hit tests can do.

**Does this specification introduce new state for an origin that persists
across browsing sessions?**

No.

**What information from the underlying platform, e.g. configuration data, is
exposed by this specification to an origin?**

None.

**Does this specification allow an origin access to sensors on a user’s
device**

No. However, in order to return hit tests results, the platform may use various
sensors. The origin has never a direct access to them as part of this
specification.

**What data does this specification expose to an origin? Please also document
what data is identical to data exposed by other features, in the same or
different contexts.**

This specification isn't directly exposing any data to the origin but can be
used to get information about the user's physical environment.

**Does this specification enable new script execution/loading mechanisms?**

No.

**Does this specification allow an origin to access other devices?**

No.

**Does this specification allow an origin some measure of control over a user
agent’s native UI?**

No.

**What temporary identifiers might this this specification create or expose to
the web?**

None.

**How does this specification distinguish between behavior in first-party and
third-party contexts?**

It is an extension to WebXR which is by default blocked for third-party contexts
and can be controlled via a Feature Policy flag.

**How does this specification work in the context of a user agent’s Private
Browsing or "incognito" mode?**

The specification does not mandate a different behaviour.

**Does this specification have a "Security Considerations" and "Privacy
Considerations" section?**

Incoming...

**Does this specification allow downgrading default security characteristics?**

No.

**What should this questionnaire have asked?**

N/A
