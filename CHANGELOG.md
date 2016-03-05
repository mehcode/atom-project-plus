## 0.7.0

* Add `ctrl-cmd-tab` and `ctrl-shift-cmd-tab` to tab through projects (by most-recently-used)
* Fix memory leak by tabs package (was recreating subscriptions on each deserialization)
* Support glob patterns in folder whitelist/blacklist — [@shemerey](https://github.com/shemerey)
* Fix folder match (for sub-folders) in whitelist/blacklist — [@shemerey](https://github.com/shemerey)

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
