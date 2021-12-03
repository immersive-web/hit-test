# hit-testing Specification

[![Build Status](https://travis-ci.org/immersive-web/hit-test.svg?branch=master)](https://travis-ci.org/immersive-web/hit-test)

The [hit-testing](https://github.com/immersive-web/hit-test) is to expose hit-testing (raycasting) capability for WebXR

The [DOM Overlays](https://immersive-web.github.io/dom-overlays/) is the 
repository of the [Immersive Web Working Group][webxrwg].

## Taking Part

1. Read the [code of conduct][CoC]
2. See if your issue is being discussed in the [issues](https://github.com/immersive-web/dom-overlays/issues), or if your idea is being discussed in the [proposals repo][cgproposals].
3. We will be publishing the minutes from the bi-weekly calls.
4. You can also join the working group to participate in these discussions.

## Specifications

* [Hit Test](https://immersive-web.github.io/hit-test/): Hit Test module specification for WebXR
* [Explainer](hit-testing-explainer.md)
* [Security and Privacy Questionnaire](security-privacy-questionnaire.md)

### Related specifications
* [WebXR Device API - Level 1][webxrspec]: Main specification for JavaScript API for accessing VR and AR devices, including sensors and head-mounted displays.

See also [list of all specifications with detailed status in Working Group and Community Group](https://www.w3.org/immersive-web/list_spec.html). 

## Relevant Links

* [Immersive Web Community Group][webxrcg]
* [Immersive Web Early Adopters Guide][webxrref]
* [Immersive Web Working Group Charter][wgcharter]

## Communication

* [Immersive Web Working Group][webxrwg]
* [Immersive Web Community Group][webxrcg]
* [GitHub issues list](https://github.com/immersive-web/dom-overlays/issues)
* [`public-immersive-web` mailing list][publiclist]

## Maintainers

To generate the spec document (`index.html`) from the `index.bs` [Bikeshed][bikeshed] document:

```sh
make
```

## Tests

For normative changes, a corresponding
[web-platform-tests][wpt] PR is highly appreciated. Typically,
both PRs will be merged at the same time. Note that a test change that contradicts the spec should
not be merged before the corresponding spec change. If testing is not practical, please explain why
and if appropriate [file a web-platform-tests issue][wptissue]
to follow up later. Add the `type:untestable` or `type:missing-coverage` label as appropriate.


## License

Per the [`LICENSE.md`](LICENSE.md) file:

> All documents in this Repository are licensed by contributors under the  [W3C Software and Document License](https://www.w3.org/Consortium/Legal/copyright-software).

# Summary

In order for web applications to make use of Augmented Reality (AR) capabilities, they must be able to identify real-world geometry. For example, a web application may wish to detect a horizontal plane (e.g, the floor) in the camera feed, and render an object (e.g, a chair) on that plane.

There are many ways that real-world geometry could be exposed through a web API. We propose starting by adding a hit-test API. This API would allow the developer to cast a ray into the real world and return a list of intersection points for that ray against whatever world understanding the underlying system gathers.

This approach abstracts the understanding of the world with a high level primitive that will work across many underlying technologies. A hit-test API would unlock a significant number of use cases for AR while allowing the work to expose other types of world understanding in a web-friendly way to proceed in parallel.

For more information about this proposal, please read the [explainer](hit-testing-explainer.md) and issues/PRs.

<!-- Links -->
[CoC]: https://immersive-web.github.io/homepage/code-of-conduct.html
[webxrwg]: https://w3.org/immersive-web
[cgproposals]: https://github.com/immersive-web/proposals
[webxrspec]: https://immersive-web.github.io/webxr/
[webxrcg]: https://www.w3.org/community/immersive-web/
[wgcharter]: https://www.w3.org/2020/05/immersive-Web-wg-charter.html
[webxrref]: https://immersive-web.github.io/webxr-reference/
[publiclist]: https://lists.w3.org/Archives/Public/public-immersive-web-wg/
[bikeshed]: https://github.com/tabatkins/bikeshed
[wpt]: https://github.com/web-platform-tests/wpt
[wptissue]: https://github.com/web-platform-tests/wpt/issues/new

