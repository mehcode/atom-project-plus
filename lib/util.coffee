_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
minimatch = require 'minimatch'
untildify = require 'untildify'
async = require 'async'
notificationManager = require './notification-manager'
{saveState} = require './provider/session'

saveCurrentState = () ->
  currentPaths = atom.project.getPaths()
  return saveState(currentPaths)

exports.saveCurrentState = saveCurrentState

# Resolve project homes
getProjectHomes = () ->
  atom.config.get('project-plus.projectHome')
    .split(',').map (pattern) -> untildify(pattern.trim())
    .filter (pattern) -> pattern.length > 0

# Get project title
getProjectTitle = (item) ->
  # NOTE: Will be adding a way to _set_ a project name
  name = (item.paths.map((pn) -> path.basename(pn))).join(",\u00a0")
  name

exports.getProjectTitle = getProjectTitle

# Sort projects
exports.sortProjects = (items) ->
  items = items.sort (a, b) ->
    aTime = if a.timestamp? then a.timestamp.getTime() else 0
    bTime = if b.timestamp? then b.timestamp.getTime() else 0
    aTime - bTime

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

    # Exclude session-provided projects if requested
    unless atom.config.get("project-plus.autoDiscover")
      return false if row.provider == "session"

    # Pass
    true

  # Name!
  rows = rows.map (row) ->
    row.title ?= getProjectTitle(row)
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

# shim atom.GetStorageFolder if its not there (1.7.0-beta)
exports.atomGetStorageFolder = () ->
  if atom.getStorageFolder?
    atom.getStorageFolder()

  else
    baseModulePath = path.dirname(path.dirname(require.resolve("atom")))
    StorageFolder = require(baseModulePath + "/src/storage-folder")
    atom.storageFolder ?= new StorageFolder(atom.getConfigDirPath())

closeAllBuffers = () ->
  buffer?.release() for buffer in atom.project.getBuffers()

exports.switchToProject = (item) ->
  require("atom-project-switch")(item.paths)
    .then ->
      projectChangeNotification(item)

    .catch (err) ->
      throw err

projectChangeNotification = (item) ->
  name = "<strong>#{item.title}</strong>"

  detail = null
  if atom.config.get('project-plus.showPath')
    detail = item.paths.join("<br/>")

  notificationManager.success("Activated project #{name}", {detail: detail})

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
