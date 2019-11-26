# Expose hit-testing (raycasting) capability for WebXR

In order for web applications to make use of Augmented Reality (AR) capabilities, they must be able to identify real-world geometry. For example, a web application may wish to detect a horizontal plane (e.g, the floor) in the camera feed, and render an object (e.g, a chair) on that plane.

There are many ways that real-world geometry could be exposed through a web API. We propose starting by adding a hit-test API. This API would allow the developer to cast a ray into the real world and return a list of intersection points for that ray against whatever world understanding the underlying system gathers.

This approach abstracts the understanding of the world with a high level primitive that will work across many underlying technologies. A hit-test API would unlock a significant number of use cases for AR while allowing the work to expose other types of world understanding in a web-friendly way to proceed in parallel.

For more information about this proposal, please read the [explainer](hit-testing-explainer.md) and issues/PRs.
