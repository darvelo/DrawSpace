# Usage

```
$ pod install
$ open DrawSpace.xcworkspace
$ cd drawspace-server
$ npm install
$ npm run docker:dev
$ npm run migration:run # run this once all Docker containers are up and running
$ npm run dc restart app # this makes the app run after the database has fully initialized

```

This will run the server on localhost at port 8082. Running the app in the simulator will allow it to connect to that server (`http://localhost:8082`).

Running `npm run docker:dev` runs a dev server on port 3000 instead. You can change the `baseUrl` in the app to point there instead.

Once creating a drawing the app will attempt to save it on the server, showing a loading indicator. If that fails, a red dot will be shown. If it succeeds, a green dot. There are buttons to refresh/sync with the server and also to delete all drawings locally and on the server. You can open a saved drawing and edit it, tapping "Done" to update it locally and remotely.

The app will use a locally-saved thumbnail if persisting to the server fails, but download and use the server image if persistence succeeded. There are reachability hooks that will attempt to retry failed saves, and tapping on an unsuccessfully saved drawing in the list will also retry while the editor is loaded.

# Implementation

I chose to create Coordinators to handle the business logic, and have them hold onto ViewControllers for UI work. I tried to rely heavily on dependency injection to allow easier testing in the future.

If I had more time I'd break up the Drawing.swift model file into separate model files and category/extension files. There was a lot of serialization/deserialization glue logic that's certainly better done with a library. I'd also prefer to use view models rather than the models directly in the UI, but I'm new to Realm and have found this way useful.

I'd also want to spend some time to work in the UINavigationController better, rather than using a workaround to prevent table updates.

I'd definitely like to write tests!
