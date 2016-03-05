# These are utils that should be in atom.
_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
minimatch = require 'minimatch'
untildify = require 'untildify'
async = require 'async'

saveCurrentState = () ->
  currentKey = atom.getStateKey(atom.project.getPaths())
  # Return if we can't get a key
  return Promise.resolve(null) unless currentKey

  # Serialize current state
  currentState = atomSerialize()

  if atom.stateStore?
    # Atom 1.7+
    atom.stateStore.save(currentKey, currentState)

  else
    # Atom 1.5 to 1.6
    store = atom.getStorageFolder()
    keypath = store.pathForKey(currentKey)
    new Promise (resolve, reject) ->
      fs.writeFile keypath, JSON.stringify(currentState), 'utf8', (err) ->
        return reject(err) if err
        resolve()

exports.saveCurrentState = saveCurrentState

# Expand whitelist and blacklist
expandConfig = () ->
  whitelist = atom.config.get('project-plus.folderWhitelist')
    .split(',').map (pattern) -> untildify(pattern.trim())

  blacklist = atom.config.get('project-plus.folderBlacklist')
    .split(',').map (pattern) -> untildify(pattern.trim())

  [whitelist, blacklist]

# Sort projects
exports.sortProjects = (items) ->
  items = items.sort (a, b) ->
    a.timestamp.getTime() - b.timestamp.getTime()

  items = items.reverse()
  items

# Filter all projects
filterProjects = (rows, options={}) ->
  _.defaults options, {
    excludeCurrent: true,
  }

  rows = _.filter rows, (row) ->
    # Is `.project` non-null
    row.project? and
    # Is `.project.paths` non-empty
    (row.project.paths || []).length > 0 and
    # Does `.project.paths` contain an array (only) of strings
    # NOTE: This one is weird -- how could the state get so corrupted?
    _.all(row.project.paths.map((pn) -> (pn || "").length > 0)) and
    # Exclude the current project if requested
    not options.excludeCurrent or not _.isEqual(
      row.project.paths, atom.project.getPaths())

  rows = rows.map (row) ->
    # NOTE: Currently the name of the project
    #       is just set to the first path's basename
    name: path.basename(row.project.paths[0])
    paths: row.project.paths
    timestamp: row.updatedAt

  # Resolve whitelist and blacklist
  [whitelist, blacklist] = expandConfig()

  # Filter according to whitelist
  if whitelist.length > 0
    rows = _.filter rows, (row) ->
      glob = "{#{whitelist.join(',')},#{whitelist.join('/**,')}/**,}"
      row.paths.filter(
        minimatch.filter(glob,  {matchBase: true, dot: true})
      ).length > 0

  if blacklist.length > 0
    rows = _.filter rows, (row) ->
      glob = "{#{blacklist.join(',')},}"
      row.paths.filter(
        minimatch.filter(glob,  {matchBase: true, dot: true})
      ).length == 0

  rows

exports.filterProjects = filterProjects

# Discover all available projects
exports.findProjects = (options) ->
  return new Promise (resolve, reject) ->
    if atom.stateStore?
      # Atom 1.7+
      # We have state serialized to IndexedDB
      # This makes this much easier

      atom.stateStore.dbPromise
        .then (db) ->
          return new Promise (dbResolve) ->
            store = db.transaction(['states']).objectStore('states')
            request = store.openCursor()
            rows = []

            request.onerror = (event) -> reject(event)
            request.onsuccess = (event) ->
              cursor = event.target.result
              if cursor
                rows.push cursor.value
                cursor.continue()

              else
                rows = rows.map (row) ->
                  result = if typeof row.value == "string" and row.isJSON
                    JSON.parse(row.value)

                  else
                    row.value

                  result.updatedAt = new Date(Date.parse(row.storedAt))
                  result

                dbResolve(rows)

        .then (rows) ->
          resolve(filterProjects(rows, options))

    else
      # Atom 1.5 to 1.6
      # Editor state is in a storage folder
      storageFolder = atom.getStorageFolder().path

      # List the storage folder
      fs.list storageFolder, (err, filenames) ->
        # Filter to only have filenames that start with editor-
        filenames = _.filter filenames, (fn) ->
          basename = path.basename(fn)
          /^editor-/.test(basename)

        # Read in the JSON data from each state file
        async.map filenames, ((filename, cb) ->
          fs.stat filename, (err, stats) ->
            return cb(err) if (err)

            updatedAt = new Date(Date.parse(stats.mtime))

            fs.readFile filename, 'utf8', (err, data) ->
              return cb(err) if (err)

              row = JSON.parse(data)
              row.updatedAt = updatedAt
              cb(null, row)

        ), (err, rows) ->
          return reject(err) if err
          resolve(filterProjects(rows, options))

# shim atom.packages.serialize in <= 1.6
packageStatesSerialize = () ->
  return atom.packages.serialize() if atom.packages.serialize?

  for pack in atom.packages.getActivePackages()
    atom.packages.setPackageState(pack.name, state) if state = pack.serialize?()

  atom.packages.packageStates

# shim atom.serialize in <= 1.6
atomSerialize = () ->
  return atom.serialize() if atom.serialize?

  # Atom <= 1.6
  {
    version: atom.constructor.version
    project: atom.project.serialize()
    workspace: atom.workspace.serialize()
    packageStates: packageStatesSerialize()
    grammars: {grammarOverridesByPath: atom.grammars.grammarOverridesByPath}
    fullScreen: atom.isFullScreen()
    windowDimensions: atom.windowDimensions
  }

# shim atom.deserialize in <= 1.6
atomDeserialize = (state) ->
  return atom.deserialize(state) if atom.deserialize?

  # Atom <= 1.6
  if grammarOverridesByPath = state.grammars?.grammarOverridesByPath
    atom.grammars.grammarOverridesByPath = grammarOverridesByPath

  atom.setFullScreen(state.fullScreen)

  atom.packages.packageStates = state.packageStates ? {}
  atom.project.deserialize(state.project, atom.deserializers) if state.project?
  atom.workspace.deserialize(state.workspace, atom.deserializers) if state.workspace?

loadState = (key) ->
  if atom.stateStore?
    # Atom 1.7+
    atom.stateStore.load(key)

  else
    # Atom <= 1.6
    Promise.resolve atom.getStorageFolder().load(key)

exports.switchToProject = (item) ->
  new Promise (resolve) ->
    # Compute new state key from paths
    newKey = atom.getStateKey(item.paths)

    # Save the state of the current project
    saveCurrentState().then () ->

      # HACK: Tab bar doesn't unsubscribe; memory leak
      tabs = atom.packages.getActivePackage("tabs")
      if tabs
        tabBarView.unsubscribe() for tabBarView in tabs.mainModule.tabBarViews

      # Load the state of the new project
      loadState(newKey).then (state) ->
        atomDeserialize(state)

        # HACK: Tree view doesn't reload expansion states
        tvState = state.packageStates["tree-view"]
        if tvState
          treeViewPack = atom.packages.getActivePackage("tree-view")
          tv = treeViewPack?.mainModule?.treeView
          if tv
            tv.updateRoots(tvState.directoryExpansionStates)
            tv.selectEntry(tv.roots[0])
            tv.selectEntryForPath(tvState.selectedPath) if tvState.selectedPath
            tv.focus() if tvState.hasFocus
            tv.scroller.scrollLeft(tvState.scrollLeft) if tvState.scrollLeft > 0
            tv.scrollTop(tvState.scrollTop) if tvState.scrollTop > 0

        # HACK: Re-focus editor (if tree-view didn't have focus)
        unless tvState.hasFocus
          atom.workspace.getActivePane().activate()

        # HACK[Pigments]: Pigments needs to reload on project reload
        pigments = atom.packages.getActivePackage("pigments")
        if pigments
          pigments.mainModule.reloadProjectVariables()

        # Done
        resolve()
