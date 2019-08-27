# WebXR Device API - Hit Testing
This document was originally designed in the Immersive Web Working Group to build upon the WebXR Device API. Ownership of this content has been moved to the Immersive Web Community Group for further incubation.

The purpose of this document is to describe a design for enabling developers to hit test against the real-world environment. For context, it may be helpful to have first read about [WebXR Session Establishment](https://github.com/immersive-web/webxr/blob/master/explainer.md), [Spatial Tracking](https://github.com/immersive-web/webxr/blob/master/spatial-tracking-explainer.md), [Input Mechanisms](https://github.com/immersive-web/webxr/blob/master/input-explainer.md), and the [Augmented Reality Module](https://github.com/immersive-web/webxr-ar-module/blob/master/ar-module-explainer.md).

## Introduction
"Hit testing" (aka "raycasting") is the process of finding intersections between 3D geometry and a ray, comprised of an origin and direction. Conceptually, hit testing can be done against virtual 3D geometry or real-world 3D geometry. As WebXR does not have any knowledge of the developer's 3D scene graph, it does not provide APIs for virtual hit testing. It does, however, have information about the real-world and provides a method for developers to hit test against it. Most commonly in WebXR, developers will hit test using `XRInputSource`s or the `XRReferenceSpace` of type `"viewer"` to track where a cursor should be drawn on hand-held devices, or even to bounce a virtual object off real-world geometry. In WebXR, 'inline' and 'immersive-vr' sessions are limited to performing virtual hit tests, while 'immersive-ar' sessions can perform both virtual and real-world hit tests.

## Real-world hit testing
A key challenge with enabling real-world hit testing in WebXR is that computing real-world hit test results can be performance-impacting and dependant on secondary threads in many of the underlying implementations. However from a developer perspective, out-of-date asynchronous hit test results are often, though not always, less than useful. 

WebXR addresses this challenge through the use of the `XRHitTestSource` type which acts somewhat like a subscription mechanism. The presence of an `XRHitTestSource` signals to the user agent that the developer intends to query `XRHitTestResult`s in subsequent `XRFrame`s. The user agent can then precompute `XRHitTestResult`s based on the `XRHitTestSource` properties such that each `XRFrame` will be bundled with all "subscribed" hit test results. When the last reference to the `XRHitTestSource` has been released, the user agent is free to stop computing `XRHitTestResult`s for future frames.

### Requesting a hit test source
To create an `XRHitTestSource` developers call the `XRSession.requestHitTestSource()` function. This function accepts an `XRHitTestOptionsInit` dictionary with the following values:
* `space` is required and is the `XRSpace` to be tracked by the hit test source. As this `XRSpace` updates its location each frame, the `XRHitTestSource` will move with it.
* `offsetRay` is optional and, if provided, is the `XRRay` from which the hit test should be performed. The ray's coordinates are defined with `space` as the origin. If an `offsetRay` is not provided, hit testing will be performed using a ray with coincident with the `space` origin and pointing in the "forward" direction. For more information on constructing an `XRRay`, see the [Spatial Tracking explainer](spatial-tracking-explainer.md#rays).

In this example, an `XRHitTestSource` is created slightly above the center of the `"viewer"` `XRReferenceSpace`. This is because the developer is planning to draw UI elements along the bottom of the hand-held AR device's immersive view while still wanting to give the perception of a centered cursor. For more information, see [Rendering cursors and highlights](#rendering-cursors-and-highlights) in the Input Explainer.

```js
let viewerHitTestSource = null;
let viewerSpace = ...;  // XRReferenceSpace obtained via
                        // a call to XRSession.requestReferenceSpace("viewer");
let hitTestOptions = { space:viewerSpace, offsetRay:new XRRay({y: 0.5}) };
xrSession.requestHitTestSource(hitTestOptions).then((hitTestSource) => {
  viewerHitTestSource = hitTestSource;
});
```

### Automatic hit test source creation
While asynchronous hit test source creation is useful in many scenarios, it is problematic for [transient input sources](#transient-Input-Sources). If an `XRHitTestSource` is requested in response to the `inputsourceschange` event, it may be several frames before a hit test source created in response would able to provide hit test results. By which time the input source may no longer exist. However, because of the potential performance impacts mentioned above, it is important WebXR not perform hit tests for input sources the developer does not need.

To solve this, user agents will automatically generate an `XRHitTestSource` for each new `XRInputSource` that developers can retrieve by calling `XRInputSourcesChangeEvent.getHitTestSource()`. Developers must explicitly retrieve and save these `XRHitTestSource`s if they wish to use them. Otherwise, at the end of the `inputsourceschange` callbacks the pre-created hit test source will disappear. If a developer chooses not to save `XRHitTestSources` in the `inputsourceschange` event handler, they are still able to use the `XRSession.requestHitTestSource()` function at a later time.

The `XRInputSourcesChangeEvent.getHitTestSource()` function will only return a `XRHitTestSource` object when passed an `XRInputSource` from the `XRInputSourcesChangeEvent.added` attribute. Any other parameter will cause a `DOMException` to be thrown.

```js
let hitTestSources = {};
function onInputSourcesChange(event) {
  xrInputSources = event.session.getInputSources();
  foreach (inputSource of event.removed) {
    delete hitTestSources[inputSource];
  }
  foreach (inputSource of event.added)
    hitTestSources[inputSource] = event.getHitTestSource(inputSource);
  }
  updatePreferredInputSource();
}
```

### Hit test results
To get synchronous hit test results for a particular frame, developers call `XRFrame.getHitTestResults()` passing in a `XRHitTestSource` as the `hitTestSource` parameter. This function will return a `FrozenArray<XRHitTestResult>` in which `XRHitTestResult`s are ordered by distance from the `XRHitTestSource`, with the nearest in the 0th position. If no results exist, the array will have a length of zero. Each entry in the array will have a `hitTestOptions` attribute filled in with `XRHitTestOptions` of the `XRHitTestSource` used to find the result. The `XRHitTestResult` interface will also expose a method, `getPose(optional XRSpace? relativeTo = null)` that can be used to query the result's pose. If no value is provided for `relativeTo` parameter, the pose will be defined in the coordinate system of the `hitTestOptions.space`. Otherwise, transforms will be defined in the coordinate system of the `relativeTo`. If `relativeTo` is present and cannot be located relative to `hitTestOptions.space` on the current frame, the function will return `null`.

```js
function updateScene(timestamp, xrFrame) {
  // Scene update logic ...
  let hitTestResults = xrFrame.getHitTestResults(hitTestSources[preferredInputSource], xrReferenceSpace);
  if (hitTestResults && hitTestResults.length > 0) {
    // Do something with the results
  }
  // Other scene update logic ...
}
```

On occasion, developers may want hit test results for the current frame even if they have not already created an `XRHitTestSource` to subscribe to the results. For example, when a virtual object needs to bounce off a real-world surface, a single hit-test result can be requested. The results will be delivered asynchronously, though they will be accurate for the frame on which the request was made. Otherwise, `requestAsyncHitTestResults()` shares the behavior of `getHitTestResults()` as described above.

```js
function updateScene(timestamp, xrFrame) {
  // Scene update logic ...
  let hitTestOptions = { space:xrSpace, offsetRay:new XRRay({}, {y: -1}) };
  xrFrame.requestAsyncHitTestResults(hitTestOptions, xrReferenceSpace).then((hitTestResults) => {
    if (hitTestResults && hitTestResults.length > 0) {
      // Do something with the results
    }
  });
  // Other scene update logic ...
}
```

#### Rays
An `XRRay` object includes both an `origin` and `direction`, both given as `DOMPointReadOnly`s. The `origin` represents a 3D coordinate in space with a `w` component that must be 1, and the `direction` represents a normalized 3D directional vector with a `w` component that must be 0. The `XRRay` also defines a `matrix` which represents the transform from a ray originating at `[0, 0, 0]` and extending down the negative Z axis to the ray described by the `XRRay`'s `origin` and `direction`. This is useful for positioning graphical representations of the ray.

## Combining virtual and real-world hit testing
A key component to creating realistic presence in XR experiences, relies on the ability to know if a hit test intersects virtual or real-world geometry. For example, developers might want to put a virtual object somewhere in the real-world but only if a different virtual object isn't already present. In future spec revisions, when real-world occlusion is possible with WebXR, developers will likely be able to create virtual buttons that are only "clickable" if there is no physical object in the way. 

There are a handful of techniques which can be used to determine a combined hit test result. For example, a developer may choose to weight hit test results differently if a user is already interacting with a particular object. In this explainer, a simple example of combining hit test results is provided: if a virtual hit-test is found it is returned, otherwise the sample returns the closest real-world hit test result. Because WebXR does not have any knowledge of the developer's 3D scene graph, this sample uses the `XRFrame.getPose()` function to create a ray and passes it into the 3D engine's virtual hit test function.

```js
function updateScene(timestamp, xrFrame) {
  // Scene update logic ...
  let hitTestResult = getHitCombinedHitTestResult(xrFrame);
  if (combinedHitTestResult["result"]) {
    // Do something with the result
  }
  // Other scene update logic ...
}
function getHitCombinedHitTestResult(frame, inputSource, hitTestSource) {
  // Try to get virtual hit test result
  if (inputSource) {
    let inputSourcePose = frame.getPose(inputSource.source, xrReferenceSpace);
    if (inputSourcePose) {
      var virtualHitTestResult = scene.virtualHitTest(new XRRay(inputSource.transform));
      return { result:virtualHitTestResult, virtualTarget:virtualHitTestResult.target }
    }
  }
  // Try to get real-world hit test result
  if (hitTestSource) {
    var realHitTestResults = frame.getHitTestResults(hitTestSource, xrReferenceSpace);
    if (realHitTestResults && realHitTestResults.length > 0) {
      return { result:realHitTestResults[0] };
    }
  }
  return {};
}
```

## Grab-and-Drag
Another common operation in XR experiences is grabbing a virtual object and moving it to a new location. There are a number of ways to accomplish this experience, and a simple example is provided below to illustrate one approach to doing so with the WebXR apis.

The first step in the grab-and-drag operation is the "grab" step and is done in response to the `selectstart` event. If a draggable virtual object is hit by the `preferredInputSource`, the drag operation is begun by saving the data necessary for the next steps and giving the object a highlight that indicates it is being dragged.

```js
let activeDragInteraction = null;
function onSelectStart(event) {
  // Select start logic ...
  // Ignore the event if we are already dragging
  if (!activeDragInteraction) {
    
    // Update the preferred input source to be the last one the user interacted with
    preferredInputSource = event.inputSource;
    // Use the input's hitTestSource to find a draggable object in the scene
    let combinedHitTestResult = getHitCombinedHitTestResult(event.frame, 
                                                            preferredInputSource, 
                                                            hitTestSources[preferredInputSource]);
    // The virtualTarget object isn't part of the WebXR API. It is
    // something set by the imaginary 3D engine in this example
    let virtualTarget = combinedHitTestResult["virtualTarget"];
    if (virtualTarget && virtualTarget.isDraggable) {
      activeDragInteraction = {
        inputSource: inputSource,
        target: virtualTarget,
        initialTargetTransform: virtualTarget.getPose().transform.matrix,
        initialHitTestResult: combinedHitTestResult["result"],
        hitTestSource = hitTestSources[preferredInputSource]
      };
      // Use imaginary 3D engine to indicate active drag object
      scene.addDragIndication(activeDragInteraction.target);
    }
  }
  // Other select start logic ...
}
```

On each frame, the location of the virtual object being dragged is updated so that it slides along virtual and real-world geometry as the user aims with their input source.

```js
function updateScene() {
  // Scene update logic ...
  if (activeDragInteraction) {
    let inputSource = activeDragInteraction.inputSource;
    let hitTestSource = activeDragInteraction.hitTestSource;
    let combinedHitTestResult = getHitCombinedHitTestResult(event.frame, inputSource, hitTestSource);
    if (combinedHitTestResult["result"]) {
      activeDragInteraction.target.setTransform(combinedHitTestResult.getPose().transform.matrix);
    }
  }
  // Other scene update logic ...
}
```

When the user releases the "select" gesture, the drag event is completed and the sample double checks that the virtual object will fit at the new location.

```js
function onSelect(event) {
  // Only end the drag when the input source that started dragging releases the select action
  if (activeDragInteraction && event.inputSource == activeDragInteraction.inputSource) {
    let combinedHitTestResult = getHitCombinedHitTestResult(event.frame, 
                                                            activeDragInteraction.inputSource, 
                                                            activeDragInteraction.hitTestSource);
    if (combinedHitTestResult["result"]) {
      let target = activeDragInteraction.target;
      let result = combinedHitTestResult["result"];
      target.setTransform(result.getPose().transform.matrix);
    } else {
      target.setTransform(activeDragInteraction.initialTargetTransform);
    }
    activeDragInteraction = null;
  }
}
function onSelectEnd(event) {
  // If the selection action was cancelled, put the object back where it started
  if (activeDragInteraction && event.inputSource == activeDragInteraction.inputSource) {
    activeDragInteraction.target.setTransform(activeDragInteraction.initialTargetTransform);
    activeDragInteraction = null;
  }
}
```

## Appendix A: Proposed partial IDL
This is a partial IDL and is considered additive to the core IDL found in the main [explainer](explainer.md).
```webidl
//
// Session
//
partial interface XRSession {
  Promise<XRHitTestSource> requestHitTestSource(XRHitTestOptionsInit options);
  // Also listed in the input-explainer.md
  attribute EventHandler oninputsourceschange;
};

//
// Frame
//
partial interface XRFrame {
  FrozenArray<XRHitTestResult>? getHitTestResults(XRHitTestSource hitTestSource);
  Promise<FrozenArray<XRHitTestResult>>? requestAsyncHitTestResults(XRHitTestOptionsInit options);
};

//
// Hit Testing
//
dictionary XRHitTestOptionsInit {
  required XRSpace space;
  XRRay offsetRay = new XRRay();
};
[SecureContext, Exposed=Window]
interface XRHitTestOptions {
  readonly attribute XRSpace space;
  readonly attributeXRRay offsetRay = new XRRay();
};
[SecureContext, Exposed=Window]
interface XRHitTestSource {
  readonly attribute XRHitTestOptions hitTestOptions;
};
[SecureContext, Exposed=Window]
interface XRHitTestResult {
  [SameObject] readonly attribute XRHitTestOptions hitTestOptions;

  XRPose? getPose(optional XRSpace? relative_to = null);
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

//
// Events
//
partial interface XRInputSourceChangeEvent {
  XRHitTestSource getHitTestSource(XRInputSource inputSource);
};
