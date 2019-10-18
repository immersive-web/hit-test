# WebXR Device API - Hit Testing
This document was originally designed in the Immersive Web Working Group to build upon the WebXR Device API. Ownership of this content has been moved to the Immersive Web Community Group for further incubation.

The purpose of this document is to describe a design for enabling developers to hit test against the real-world environment. For context, it may be helpful to have first read about [WebXR Session Establishment](https://github.com/immersive-web/webxr/blob/master/explainer.md), [Spatial Tracking](https://github.com/immersive-web/webxr/blob/master/spatial-tracking-explainer.md), [Input Mechanisms](https://github.com/immersive-web/webxr/blob/master/input-explainer.md), and the [Augmented Reality Module](https://github.com/immersive-web/webxr-ar-module/blob/master/ar-module-explainer.md).

## Introduction
"Hit testing" (aka "raycasting") is the process of finding intersections between 3D geometry and a ray, comprised of an origin and direction. Conceptually, hit testing can be done against virtual 3D geometry or real-world 3D geometry. As WebXR does not have any knowledge of the developer's 3D scene graph, it does not provide APIs for virtual hit testing. It does, however, have information about the real-world and provides a method for developers to hit test against it. Most commonly in WebXR, developers will hit test using `XRInputSource`s or the `XRReferenceSpace` of type `"viewer"` to track where a cursor should be drawn on hand-held devices, or even to bounce a virtual object off real-world geometry. In WebXR, 'inline' and 'immersive-vr' sessions are limited to performing virtual hit tests, while 'immersive-ar' sessions can perform both virtual and real-world hit tests.

## Use-cases & scope
Main use-cases enabled by such an API include:

* Showing a reticle that appears to track the real world surfaces at which the device or controller is pointed.
  * Often, AR apps want to show a reticle that appears to stick to real-world surfaces. The reticle position should reflect most up-to-date knowledge of the real world as of the displayed frame.
  * Frequency: this action is done every single frame.
* Placing a virtual object in the real world.
  * In order for virtual objects to appear to be anchored in the real world, they must be placed at the same height as the real world objects (the floor, a table, a wall, ...).
  * Frequency: this action is usually done sparsely, in response to user input.
* Simulating physical interactions with real-world.
  * Applications may want leverage hit testing API in order to simulate physical interactions (for example collisions) of virtual objects with the real world.
  * Frequency: this action is done every single frame.

Hit-testing against application's virtual scene elements is explicitly out of scope for this explainer. Hit-testing API might potentially be used to estimate the location of real-world geometry by the application (for example by attempting to perform a hit test using dozens of rays) - this use case is not directly supported by the API, but will not be actively blocked. Due to this fact, access to hit-testing API should be only allowed after explicit user consent equivalent to the consent required for access to any other real-world-understanding APIs.

## Real-world hit testing
A key challenge with enabling real-world hit testing in WebXR is that computing real-world hit test results can be performance-impacting and dependant on secondary threads in many of the underlying implementations. However from a developer perspective, out-of-date asynchronous hit test results are often, though not always, less than useful. 

WebXR addresses this challenge through the use of the `XRHitTestSource` type which acts like a subscription mechanism. The presence of an `XRHitTestSource` signals to the user agent that the developer intends to query `XRHitTestResult`s in subsequent `XRFrame`s. The user agent can then precompute `XRHitTestResult`s based on the `XRHitTestSource` properties such that each `XRFrame` will be bundled with all "subscribed" hit test results. When the last reference to the `XRHitTestSource` has been released, the user agent is free to stop computing `XRHitTestResult`s for future frames.

### Requesting a hit test source
To create an `XRHitTestSource` developers call the `XRSession.requestHitTestSource()` function. This function accepts an `XRHitTestOptionsInit` dictionary with the following key-value pairs:
* `space` is required and is the `XRSpace` to be tracked by the hit test source. As this `XRSpace` updates its location each frame, the `XRHitTestSource` will move with it.
* `offsetRay` is optional and, if provided, is the `XRRay` from which the hit test should be performed. The ray's coordinates are defined with `space` as the origin. If an `offsetRay` is not provided, hit testing will be performed using a ray with coincident with the `space` origin and pointing in the "forward" direction (see [Rays section](#Rays)).

In this example, an `XRHitTestSource` is created slightly above the center of the `"viewer"` `XRReferenceSpace`. This is because the developer is planning to draw UI elements along the bottom of the hand-held AR device's immersive view while still wanting to give the perception of a centered cursor. For more information, see [Rendering cursors and highlights](https://github.com/immersive-web/webxr/blob/master/input-explainer.md#cursors) in the Input Explainer.

```js
let viewerHitTestSource = null;
let viewerSpace = ...;  // XRReferenceSpace obtained via
                        // a call to XRSession.requestReferenceSpace("viewer");
let hitTestOptionsInit = {
  space : viewerSpace,
  offsetRay : new XRRay({y: 0.5})
};

xrSession.requestHitTestSource(hitTestOptionsInit).then((hitTestSource) => {
  viewerHitTestSource = hitTestSource;
  // Store some additional data on just created hit test source
  // by extending the object:
  viewerHitTestSource.appContext = { options : hitTestOptionsInit };
});
```

### Pre-registration for transient input sources
While asynchronous hit test source creation is useful in many scenarios, it is problematic for [transient input sources](https://immersive-web.github.io/webxr/#transient-input). If an `XRHitTestSource` is requested in response to the `inputsourceschange` event using the `XRSession.requestHitTestSource()` API, it may take several frames before a hit test source created in response would able to provide hit test results, by which time the input source may no longer exist. This might be the case even with a one-frame delay between hit test source creation request and its creation. However, because of the potential performance impacts mentioned in section [Real-world hit testing](#real-world-hit-testing), it is important WebXR not perform hit tests for input sources the developer does not need.

To address this issue and still enable the web applications to request hit test sources for transient input sources, the applications can use the `XRSession.requestHitTestSourceForTransientInput()`:

```javascript
let transientInputHitTestSource = null;
let hitTestOptionsInit = {
  profile : 'generic-touchscreen',
  offsetRay : new XRRay()
};

xrSession.requestHitTestSourceForTransientInput(hitTestOptionsInit).then((hitTestSource) => {
  transientInputHitTestSource = hitTestSource;
  // Store some additional data on just created hit test source
  // by extending the object:
  transientInputHitTestSource.context = { options : hitTestOptionsInit };
})
```

The `XRSession.requestHitTestSourceForTransientInput()` method accepts a dictionary with the following key-value pairs:
* `profile` is required and specifies the input profile name (see [input profile names](https://immersive-web.github.io/webxr/#xrinputsource-input-profile-name)) that the transient input source must match in order to be considered for a hit test once it is created (for example in response to the user input).
* `offsetRay` is optional and specifies an `XRRay` for which the hit test should be performed. The ray will be interpreted as if relative to `targetRaySpace` of the transient input source that matches `targetRayMode`.

### Hit test results
To get synchronous hit test results for a particular frame, developers call `XRFrame.getHitTestResults()` passing in a `XRHitTestSource` as the `hitTestSource` parameter. This function will return a `FrozenArray<XRHitTestResult>` in which `XRHitTestResult`s are ordered by distance along the `XRRay` used to perform the hit test, with the nearest in the 0th position. If no results exist, the array will have a length of zero. The `XRHitTestResult` interface will expose a method, `getPose(XRSpace baseSpace)` that can be used to query the result's pose. If, in the current frame, the relationship between `XRSpace` passed in to `baseSpace` parameter cannot be located relative to the hit test result, the function will return `null`.

```js
// Input source returned from a call to XRSession.requestHitTestSource(...):
let hitTestSource = ...;

function updateScene(timestamp, xrFrame) {
  // Scene update logic ...
  let hitTestResults = xrFrame.getHitTestResults(hitTestSource);
  if (hitTestResults.length > 0) {
    // Do something with the results
  }
  // Other scene update logic ...
}
```

In order to obtain hit test results for transient input source hit test subscriptions in a particular frame, developers call `XRFrame.getHitTestResultsForTransientInput()` passing in a `XRTransientInputHitTestSource` as the `hitTestSource` parameter. This function will return a `FrozenArray<XRTransientInputHitTestResult>`. Each element of the array will contain an instance of the input source that was used to obtain the results, and the actual hit test results will be contained in `FrozenArray<XRHitTestResult> results`, ordered by the distance along the ray used to perform the hit test, with the closest result at 0th position.

```js
// Input source returned from a call to
// XRSession.requestHitTestSourceForTransientInput(...):
let transientInputHitTestSource = ...;

function updateScene(timestamp, xrFrame) {
  // Scene update logic ...
  let hitTestResultsPerInputSource = xrFrame.getHitTestResultsForTransientInput(transientInputHitTestSource);

  hitTestResultsPerInputSource.forEach(resultsPerInputSource => {
    if(!isInteresting(resultsPerInputSource.inputSource)) {
      return; // Application can perform additional
              // filtering based on the input source.
    }

    if (resultsPerInputSource.results.length > 0) {
    // Do something with the results
    }
  });
  // Other scene update logic ...
}
```

### Limiting results to specific entities
Hit test results returned from the underlying platform can carry an information about the real-world entity that caused the hit test result to be present. Examples of the entities include planes and feature points. The application can specify what kind of entities should be used for a particular hit test subscription by setting a value of `entityTypes` key in `XRHitTestOptionsInit` / `XRTransientInputHitTestOptionsInit`:

```js

let hitTestOptionsInit = {
  space : xrSpace,
  entityTypes : ["plane", "point"],
  offsetRay : XRRay()
};

let transientInputHitTestOptionsInit = {
  profile : "generic-touchscreen",
  entityTypes : ["plane"],
  offsetRay : XRRay()
};

```

Using multiple values in the array set for `entityTypes` key will be treated as a logical "or" filter. For example `entityTypes : ["plane", "point"]` would mean that the arrays returned from `XRFrame.getHitTestResults()` / `XRFrame.getHitTestResultsForTransientInput()` will contain hit tests based off of real-world planes, as well as results based off of characteristic points detected in the user's environment; those are the hit test results whose entities satisfy a condition `(type == "plane") or (type == "point")`, assuming that the `type` contains a type of the given entity. If the application does not set a value for `entityTypes` key when requesting hit test source, a default value of `["plane"]` will be used.

#### Rays
An `XRRay` object includes both an `origin` and `direction`, both given as `DOMPointReadOnly`s. The `origin` represents a 3D coordinate in space with a `w` component that must be equal to 1, and the `direction` represents a normalized 3D directional vector with a `w` component that must be equal to 0. The `XRRay` also defines a `matrix` which represents the transform from a ray originating at `[0, 0, 0]` and extending down the negative Z axis to the ray described by the `XRRay`'s `origin` and `direction`. This is useful for positioning graphical representations of the ray.

## Combining virtual and real-world hit testing
A key component to creating realistic presence in XR experiences, relies on the ability to know if a hit test intersects virtual or real-world geometry. For example, developers might want to put a virtual object somewhere in the real-world but only if a different virtual object isn't already present. In future spec revisions, when real-world occlusion is possible with WebXR, developers will likely be able to create virtual buttons that are only "clickable" if there is no physical object in the way. 

There are a handful of techniques which can be used to determine a combined hit test result. For example, a developer may choose to weight hit test results differently if a user is already interacting with a particular object. In this explainer, a simple example of combining hit test results is provided: if a virtual hit-test is found it is returned, otherwise the sample returns the closest real-world hit test result. Because WebXR does not have any knowledge of the developer's 3D scene graph, this sample uses the `XRFrame.getPose()` function to create a ray and passes it into the 3D engine's virtual hit test function.

```js
function getCombinedHitTestResult(frame, inputSource, hitTestSource) {
  // Try to get virtual hit test result
  if (inputSource) {
    let inputSourcePose = frame.getPose(inputSource.targetRaySpace, xrReferenceSpace);
    if (inputSourcePose) {
      var virtualHitTestResult = scene.virtualHitTest(new XRRay(inputSourcePose.transform));
      return {
        result : virtualHitTestResult,
        virtualTarget : virtualHitTestResult.target
      }
    }
  }
  // Try to get real-world hit test result
  if (hitTestSource) {
    var realHitTestResults = frame.getHitTestResults(hitTestSource);
    if (realHitTestResults && realHitTestResults.length > 0) {
      return { result : realHitTestResults[0] };
    }
  }
  return {};
}
```

## Appendix A: Proposed partial IDL
This is a partial IDL and is considered additive to the core IDL found in the main [explainer](https://github.com/immersive-web/webxr/blob/master/explainer.md).
```webidl
//
// Session
//
partial interface XRSession {
  Promise<XRHitTestSource> requestHitTestSource(XRHitTestOptionsInit options);
  Promise<XRTransientInputHitTestSource> requestHitTestSourceForTransientInput(XRTransientInputHitTestOptionsInit options);
};

//
// Frame
//
partial interface XRFrame {
  FrozenArray<XRHitTestResult> getHitTestResults(XRHitTestSource hitTestSource);
  FrozenArray<XRTransientInputHitTestResult> getHitTestResultsForTransientInput(XRTransientInputHitTestSource hitTestSource);
};

//
// Hit Testing Options
//
enum XRHitTestTrackableType {
  "point",
  "plane"
};

dictionary XRHitTestOptionsInit {
  required XRSpace space;
  FrozenArray<XRHitTestTrackableType> entityTypes;
  XRRay offsetRay = new XRRay();
};

dictionary XRTransientInputHitTestOptionsInit {
  required DOMString profile;
  FrozenArray<XRHitTestTrackableType> entityTypes;
  XRRay offsetRay = new XRRay();
};

//
// Hit Test Sources
//
[SecureContext, Exposed=Window]
interface XRHitTestSource {
};

[SecureContext, Exposed=Window]
interface XRTransientInputHitTestSource {
};

//
// Hit Test Results
//
[SecureContext, Exposed=Window]
interface XRHitTestResult {
  XRPose? getPose(XRSpace baseSpace);
};

[SecureContext, Exposed=Window]
interface XRTransientInputHitTestResult {
  [SameObject] readonly attribute XRInputSource inputSource;
  FrozenArray<XRHitTestResult> results;
};

//
// Geometric Primitives
//
[SecureContext, Exposed=Window,
 Constructor(optional DOMPointInit origin, optional DOMPointInit direction),
 Constructor(XRRigidTransform transform)]
interface XRRay {
  [SameObject] readonly attribute DOMPointReadOnly origin;
  [SameObject] readonly attribute DOMPointReadOnly direction;
  [SameObject] readonly attribute Float32Array matrix;
};

