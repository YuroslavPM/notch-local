# 08 - Testing checklist

Run `make run` first. Go through this list after every step (the relevant sections) and fully before pushing.

## Window and placement

- [ ] Black shape matches the notch width and sits flush with the top edge
- [ ] Stays visible on every Space (swipe between desktops)
- [ ] Stays visible above fullscreen Safari / YouTube / Keynote
- [ ] External display without a notch shows the 200 x 24 handle
- [ ] Plugging or unplugging a display re-positions the panel correctly
- [ ] After sleep / wake the panel is still in the right place

## Interaction

- [ ] Hover opens the panel quickly with a smooth spring
- [ ] Moving away closes it after about 300 ms; returning cancels the close
- [ ] Collapsed: clicks under the expanded area reach the app below
- [ ] Expanded: clicking buttons does not steal focus from the frontmost app
- [ ] Dragging a file near the top of the screen does not break hover state

## Music

- [ ] Spotify playing: title, artist, artwork, all three buttons work
- [ ] Apple Music playing: same
- [ ] Both closed: "Nothing playing", neither app is launched
- [ ] Paused state shows the play icon
- [ ] Track change updates within about 1 s
- [ ] Automation denied: hint shown, no crash (`tccutil reset AppleEvents com.yuroslav.notchlocal` to re-test)

## Calendar

- [ ] First expand prompts for Calendar access
- [ ] Granted: events show with colors and correct relative times
- [ ] No events: "No more events today"
- [ ] Denied: message plus working settings button (`tccutil reset Calendar com.yuroslav.notchlocal` to re-test)
- [ ] New event in Calendar.app appears within a few seconds

## Lifecycle

- [ ] No Dock icon, not in Cmd+Tab
- [ ] Menu bar Quit ends the process
- [ ] Menu bar Restart relaunches cleanly
- [ ] Launching twice leaves one instance

## Performance

- [ ] Idle CPU near 0% while collapsed (Activity Monitor)
- [ ] Memory stays roughly stable after 30 minutes of music playback

## Ship

- [ ] All steps committed (`step 02` to `step 07`)
- [ ] `git push -u origin main`
