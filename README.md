Multipeer.Instrument
====================

A sample app designed to help instrument the behavior of iOS Multipeer API, while also having a little fun.

Any iOS device that is running the app and is within Bluetooth LE range or on the same wifi network will automatically recieve an invitation to join a shared session.  The invitation will be automatically accepted creating an experience of seeing devices come and go as they join/leave the mesh network.

As devices join they are listed with some associated controls; currently two sliders and an on/off switch.  The on/off switch will trigger a song to play on the device for which the switch was pressed.  The slider below the on/off switch will control the volume of the song being played.  And the second slider will control the brightness of the screen.

Since the app is not useful if only one phone is running, follow the steps below to get it running in a simulator.  Then follow the same steps to run on your device.  Once you have it on both, open them at the same time and they should show up as having joined the session.


Running the App locally
=======================

The project is using CocoaPods for a few helper libraries.  If you don't have it installed already, go to cocoapods.org and follow the steps to install.  It will be used in step 2 below.

1. Clone the repository >git clone https://github.com/kbeyer/Multipeer.Instrument.git
2. Install the CocoaPod dependencies.  Run 'pod install' at root of project directory.
3. Open Multipeer.Instrument.workspace in Xcode v5+
4. Make sure the 'Develop' Scheme is chosen and then click Run.


Running Node locally
====================

To see the instrumented events as the iOS app is running, you will need to run the node server project so that there is an endpoint to which REST calls will be made.

The Node app uses MongoDB to store events.  You can either run mongo locally (default configuration) or change the connection string to use a hosted instance.

1. When working with node, it's easiest to run commands from the Node folder >cd Node
2. Start Mongo (or configure the url to existing instance) >mongod
3. Install and update the npm modules >npm install
4. Run the Node app >node index.js


The default page is connected to a socket which will append events sent to the Node REST API from the iOS app in real-time to the text area.

In the future, there will be charts that visualize the events and associated information.


Running iOS app and Node together
=================================

To see the instrumented events via the Node app, start Node first, then the app.  The iOS app running in your local simulator is configured by default to log events to http://localhost:3000.  To also log events from an iOS app that isn't running on your local computer, you will need to configure the URL appropriate and make sure it is accessible.


Directory Structure
===================

```
/Frameworks -> External frameworks
/Node       -> Implementation of Node app for logging instrumented events
/Pods       -> Cocoapods project, associated files, and configuration
/Resources  -> iOS app resources
/Source     -> iOS application source code
```


