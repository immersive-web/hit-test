# Expose hit-testing (raycasting) capability for WebXR

## Background
In order for web applications to make use of Augmented Reality (AR) capabilities, they must be able to identify real-world geometry. For example, a web application may wish to detect a horizontal plane (e.g, the floor) in the camera feed, and render an object (e.g, a chair) on that plane.

There are many ways that real-world geometry could be exposed through a web API. We propose starting by adding a hit-test API. This API would allow the developer to cast a ray into the real world and return a list of intersection points for that ray against whatever world understanding the underlying system gathers.

This approach abstracts the understanding of the world with a high level primitive that will work across many underlying technologies. A hit-test API would unlock a significant number of use cases for AR while allowing the work to expose other types of world understanding in a web-friendly way to proceed in parallel.

## Use Cases

Use-cases enabled by such an API include:

* Place a virtual object in the real world

  The most common form of real-world geometry that is used are horizontal surfaces on which apps would like to place virtual objects. In order for those virtual objects to appear to be anchored in the real world, they must be placed at the same height as the ground/table in the real world.
Usually the placement is in response to a user gesture such as a tap. On tap, the app wants to cast a ray into the world emanating from the touch location and get a hit result that represents the location and orientation in the real world that ray would intersect so the object can be placed realistically.
A hitTest API would allow the developer to detect geometry in response to a user gesture, and use the results to determine where to place/render the virtual object.
Frequency: this action is usually done sparsely - that is once every several seconds or even minutes in response to user input.

* Show a reticle in the center of the device that appears to track the real world surfaces that the device or controller is pointed at.

  Often, AR apps want to show a reticle that appears to stick to real-world surfaces (sometimes as part of the above functionality). In order to do this, the app could perform a hit-test every frame, usually based on a ray that emanates from the center of the screen. This would allow the developer to render the reticle appropriately on real-world surfaces as the scene changes.
Frequency: this action is done every single frame based on a consistent ray

## Proposed Approach
Technologies for identifying real-world geometry from the camera input are becoming available on mobile devices, and the user agent could use these to implement a hit-test API. The simplicity of this API also enables a wide range of implementation choices and input types. The intent is to explore an extension to the WebXR Device API - one abstracted from world understanding and closely connected to device pose and frame production - because the ability to render data over the real world (whether in passthrough or see-through mode) requires a strong connection between pose and world understanding.

## For illustration purposes, such an API might look like the following:

`XRPresentationFrame::hitTest(XRPose rayPose) -> Promise<sequence<XRHitResult>>`

Input is a pose (position/orientation or matrix) whose position represents the origin of the raycast and whose orientation represents the direction of the raycast
The return value is a sequence of XRHitResult that contain an XRPose which represents all the hit locations the ray intersected with. In the future, it also may contain other fields (such as the object that was hit)
