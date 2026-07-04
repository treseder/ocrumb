# ocrumb

Native SwiftUI iOS app for ocrumb — snap a photo of a recipe and get back a
structured recipe (title, ingredients, steps, times). Talks to the ocrumb Rails
API at [`~/code/ocrumb-web`](../ocrumb-web).

## Local development

Debug builds target `http://localhost:3000` by default, and the iOS Simulator
shares the Mac's network — so running against a local backend needs no app
changes. Release builds are pinned to the production URL
(`APIConfig.productionBaseURL`).

### 1. Start the backend

```bash
cd ~/code/ocrumb-web
bin/setup                      # bundle install + db:prepare (first run only)
OPENAI_API_KEY=sk-... bin/dev  # boots Puma on 0.0.0.0:3000
```

- `bin/dev` runs the async extraction jobs in-process (Solid Queue in Puma), so
  no separate worker is needed.
- `OPENAI_API_KEY` is required for successful extraction. Without it, uploads
  still work but each recipe lands in the `failed` extraction state.

### 2. Run the app

Build and run the `ocrumb` scheme on a simulator (e.g. iPhone 17), then:

- **Register** a new account in-app (there is no seeded user).
- Add a photo to the simulator (drag an image onto the window), then upload it
  from the **+** screen.

### Pointing at a different backend

In debug builds the base URL can be overridden without recompiling via the
`ocrumb.baseURL` `UserDefaults` key — e.g. add a scheme launch argument:

```
-ocrumb.baseURL https://staging.example.com
```

Release builds ignore the override and always use
`APIConfig.productionBaseURL`.

### Physical device

`bin/dev` already listens on the LAN, so a device on the same Wi-Fi can reach
`http://<your-mac-ip>:3000`. Two extra steps apply (not needed for the
simulator): set `ocrumb.baseURL` to that address, and add an App Transport
Security exception in Info.plist, since iOS blocks non-localhost cleartext HTTP.

## Tests

```bash
xcodebuild test -scheme ocrumb -destination 'platform=iOS Simulator,name=iPhone 17'
```
