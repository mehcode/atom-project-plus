_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
minimatch = require 'minimatch'
untildify = require 'untildify'
async = require 'async'
notificationManager = require './notification-manager'
atomProjectUtil = require 'atom-project-util'

saveCurrentState = () ->
  currentPaths = atom.project.getPaths()
  return atomProjectUtil.save(currentPaths)

exports.saveCurrentState = saveCurrentState

# Resolve project homes
getProjectHomes = () ->
  atom.config.get('project-plus.projectHome')
    .split(',').map (pattern) -> untildify(pattern.trim())
    .filter (pattern) -> pattern.length > 0

# Get project title
getProjectTitle = (item) ->
  return item.title if (item.title or "").length > 0

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

exports.switchToProject = (item) ->
  atomProjectUtil.switch(item.paths)
    .then ->
      projectChangeNotification(item)

    .catch (err) ->
      throw err

projectChangeNotification = (item) ->
  name = "<strong>#{getProjectTitle(item)}</strong>"

  detail = null
  if atom.config.get('project-plus.showPath')
    detail = item.paths.join("<br/>")

  notificationManager.success("Activated project #{name}", {detail: detail})

exports.closeProject = () ->
  atomProjectUtil.close()
