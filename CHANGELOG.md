## 0.8.0

* Remove `folderBlacklist` configuration option
* Rename `folderWhitelist` to `projectHome`
* Default `showPath` to false
* Add `project-plus:save` command; explicit save of the project
* Separate out project discovery from the project switching; take what we had as project discovery and make it it an isolated component, `SessionProvider`
* :tada: Support `projects.cson` from [project manager](https://github.com/danielbrodin/atom-project-manager) as `FileProvider`
* Add a configuration option to turn off project detection from session storage — `project-plus.autoDiscover`
* Add notifications on command success (for project switch and save) — [@shemerey](https://github.com/shemerey)

## 0.7.0

* Add `ctrl-cmd-tab` and `ctrl-shift-cmd-tab` to tab through projects (by most-recently-used)
* Fix memory leak by tabs package (was recreating subscriptions on each deserialization)
* Support glob patterns in folder whitelist/blacklist — [@shemerey](https://github.com/shemerey)
* Fix folder match (for sub-folders) in whitelist/blacklist — [@shemerey](https://github.com/shemerey)
* :bug: Fix #19; reload pigments on project switch
* :bug: Fix #20; remove attach line for tree-view
* Add `showPath` config; allow paths to be toggled from the finder
* :sparkles: Improve visual display of multi-path projects (ref #8)
* :hammer: Close #5; add ability to switch to a project from a folder picker
* :hammer: Add ability to close the current project and get an empty atom window

## 0.6.0

* Sort projects by most-recently-used (MRU)

## 0.5.0

* Add folder whitelist and blacklist configuration options — [@shemerey](https://github.com/shemerey)

## 0.4.0

* Unify switch and open commands
* Add keybindings (mirroring sublime)

## 0.3.0

* Backport to Atom 1.5 and 1.6
* :bug: Cursor was not re-appearing on project switch

## 0.2.0

* Initial "It Works, Jim" release
