
# ScreenCaptureKit Demo


A demo for using ScreenCaptureKit to capture screenshots and streaming screen contents.

![](./overallDemo.gif)


## Screenshot

1. Screenshot a specific area, an app, a window. 
    - user-selectable or programmatically set
2. Additional configurations such as output the image directly to a file, hiding cursor, and etc.

For more details, please check out my article: [SwiftUI: Screenshot Programmatically on MacOS]()


![](./screenshotDemo.gif)


## Screen Streaming / Recording

1. Screen Streaming or streaming + recording
    - a specific area, an app, a window, or display (user-selectable or programmatically set)
    - recording start/stop together with the streaming or individually
    - automatically resume recording into a new file when current recording stopped due to change in stream configuration
2. Additional configurations such as color space (gray scale vs default), hiding/showing cursor, excluding current app, and etc.

For more details, please check out my article: [SwiftUI: Screen Capturing (Streaming/Sharing/Recording) on MacOS]()


![](./screenCaptureDemo.gif)


## Additional

### Team & Signature
If we don't have a development team selected and the Signing Certificate is signed to Run Locally, 
we will receive the prompt asking us to grant app the permission to record computer screen and audio pretty much every single time trying to run the app.
<br>
And if we open the system setting, 
the app will actually already be added and turned on, ie: allowed. 
However, we won't be capture screenshot because if it is signed to Run Locally, 
a different version of the app is probably currently being ran than the added one.
So what we will have to do is to delete the added one, re-run the app, open the system settings, enable it, relaunch the app again.

<br><br>
Therefore, I strongly recommended to select a team and set the Signing Certificate to Development so the prompt will only show up once forever.


### Full Screen Overlay

For more details on presenting/controlling full screen overlay, please check out [SwiftUI/MacOS: Full Screen Cover / Overlay]()
