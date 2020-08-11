# Usage

`
npm install
npm run docker
`

This will run the server on localhost at port 8082. Running the app in the simulator will allow it to connect to that server (`http://localhost:8082`).

Running `npm run docker:dev` runs a dev server on port 3000 instead. You can change the `baseUrl` in the app to point there instead.

# Implementation

I chose to create Coordinators to handle the business logic, and have them hold onto ViewControllers for UI work. I tried to rely heavily on dependency injection to allow easier testing in the future.

If I had more time I'd break up the Drawing.swift model file into different models. I'd also prefer to use view models rather than the models directly in the UI, but I'm new to Realm and have found this way useful.

I'd also want to spend some time to work in the UINavigtionController better, rather than using a workaround to prevent table updates.

I'd definitely like to write tests!
