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

# Resolve project homes
getProjectHomes = () ->
  atom.config.get('project-plus.projectHome')
    .split(',').map (pattern) -> untildify(pattern.trim())
    .filter (pattern) -> pattern.length > 0

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
    # Is `.paths` non-empty
    return false unless (row.paths || []).length > 0

    # Does `.paths` contain an array (only) of strings
    # NOTE: This one is weird -- how could the state get so corrupted?
    return false unless _.all(row.paths.map(
      (pn) -> (pn || "").length > 0))

    # Exclude the current project if requested
    if options.excludeCurrent
      return false if _.isEqual(row.paths, atom.project.getPaths())

    # Pass
    true

  # Name!
  rows = rows.map (row) ->
    # NOTE: Will be adding a way to _set_ a project name
    name = (row.paths.map((pn) -> path.basename(pn))).join(",\u00a0")
    row.name = name
    row

  # Resolve Project Home
  projectHomes = getProjectHomes()

  # Filter according to Project Home
  if projectHomes.length > 0
    pattern = "{#{projectHomes.join(',')},#{projectHomes.join('/**,')}/**,}"
    rows = _.filter rows, (row) ->
      row.paths.filter(
        minimatch.filter(pattern, {matchBase: true, dot: true})
      ).length > 0

  rows

exports.filterProjects = filterProjects

# shim atom.packages.serialize in <= 1.6
packageStatesSerialize = () ->
  return atom.packages.serialize() if atom.packages.serialize?

  for pack in atom.packages.getActivePackages()
    atom.packages.setPackageState(pack.name, state) if state = pack.serialize?()

  atom.packages.packageStates

# shim atom.serialize in <= 1.6
atomSerialize = () ->
  options = {isUnloading: true}
  return atom.serialize(options) if atom.serialize?

  # Atom <= 1.6
  {
    version: atom.constructor.version
    project: atom.project.serialize(options)
    workspace: atom.workspace.serialize()
    packageStates: packageStatesSerialize()
    grammars: {grammarOverridesByPath: atom.grammars.grammarOverridesByPath}
    fullScreen: atom.isFullScreen()
    windowDimensions: atom.windowDimensions
  }

exports.atomSerialize = atomSerialize

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

# shim atom.GetStorageFolder if its not there (1.7.0-beta)
exports.atomGetStorageFolder = () ->
  baseModulePath = path.dirname(path.dirname(require.resolve("atom")));
  StorageFolder = require(baseModulePath + "/src/storage-folder");
  atom.storageFolder ?= new StorageFolder(atom.getConfigDirPath())

loadState = (key) ->
  if atom.stateStore?
    # Atom 1.7+
    atom.stateStore.load(key)

  else
    # Atom <= 1.6
    Promise.resolve atom.getStorageFolder().load(key)

closeAllBuffers = () ->
  buffer?.release() for buffer in atom.project.getBuffers()

exports.switchToProject = (item) ->
  new Promise (resolve) ->
    # Get current state key
    currentKey = atom.getStateKey(atom.project.getPaths())

    # Compute new state key from paths
    newKey = atom.getStateKey(item.paths)

    # Save the state of the current project
    saveCurrentState().then () ->

      # Load the state of the new project
      loadState(newKey).then (state) ->
        if state
          atomDeserialize(state)

          # HACK: Tree view doesn't reload expansion states
          tvState = state.packageStates["tree-view"]
          if tvState
            treeViewPack = atom.packages.getActivePackage("tree-view")
            tv = treeViewPack?.mainModule?.treeView
            if tv
              # NOTE: Re-attach the tree-view if this is an empty atom
              tv.attach() if not currentKey and not tv.isVisible()
              tv.updateRoots(tvState.directoryExpansionStates)
              tv.selectEntry(tv.roots[0])
              tv.selectEntryForPath(tvState.selectedPath) if tvState.selectedPath
              tv.focus() if tvState.hasFocus
              tv.scroller.scrollLeft(tvState.scrollLeft) if tvState.scrollLeft > 0
              tv.scrollTop(tvState.scrollTop) if tvState.scrollTop > 0

              # HACK: Re-focus editor (if tree-view didn't have focus)
              unless tvState.hasFocus
                atom.workspace.getActivePane().activate()
        else
          # Set project paths
          atom.project.setPaths(item.paths)

          # Close all buffers
          closeAllBuffers()

        # HACK[Pigments]: Pigments needs to reload on project reload
        pigments = atom.packages.getActivePackage("pigments")
        if pigments
          pigments.mainModule.reloadProjectVariables()

        # Done
        resolve()

exports.closeProject = () ->
  # Save the state of the current project
  saveCurrentState().then () ->
    # Set project paths
    atom.project.setPaths([])

    # Close all buffers
    closeAllBuffers()

    # TODO: Should we close the tree-view?
    treeViewPack = atom.packages.getActivePackage("tree-view")
    tv = treeViewPack?.mainModule?.treeView
    if tv
      tv.detach() if tv.isVisible()
