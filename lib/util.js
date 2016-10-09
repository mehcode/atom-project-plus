'use babel'

import _ from 'underscore-plus'
import path from 'path'
import minimatch from 'minimatch'
import untildify from 'untildify'
import notificationManager from './notification-manager'
import atomProjectUtil from 'atom-project-util'

export function saveCurrentState () {
  const currentPaths = atom.project.getPaths()
  return atomProjectUtil.save(currentPaths)
}

// Resolve project homes
function getProjectHomes () {
  return atom.config.get('project-plus.projectHome')
    .split(',').map(pattern => untildify(pattern.trim()))
    .filter(pattern => pattern.length > 0)
}

// Get project title
export function getProjectTitle (item) {
  if ((item.title || '').length > 0) return item.title

  // NOTE: Will be adding a way to _set_ a project name
  let name = (item.paths.map(pn => path.basename(pn))).join(',\u00a0')
  return name
};

// Sort projects
export function sortProjects (items) {
  items = items.sort((a, b) => {
    const aTime = (a.timestamp != null) ? a.timestamp.getTime() : 0
    const bTime = (b.timestamp != null) ? b.timestamp.getTime() : 0
    return aTime - bTime
  })

  items = items.reverse()
  return items
}

// Filter all projects
export function filterProjects (rows, options = {}) {
  _.defaults(options, {
    excludeCurrent: true
  })

  rows = _.filter(rows, row => {
    // Is `.paths` non-empty
    if ((row.paths || []).length <= 0) return false

    // Does `.paths` contain an array (only) of strings
    // NOTE: This one is weird -- how could the state get so corrupted?
    if (!_.all(row.paths, pn => (pn || '').length > 0)) return false

    // Exclude the current project if requested
    if (options.excludeCurrent) {
      if (_.isEqual(row.paths, atom.project.getPaths())) return false
    }

    // Exclude session-provided projects if requested
    if (!atom.config.get('project-plus.autoDiscover')) {
      if (row.provider === 'session') return false
    }

    // Pass
    return true
  })

  // Name!
  for (const row of rows) {
    row.title = row.title || getProjectTitle(row)
  }

  // Resolve Project Home
  const projectHomes = getProjectHomes()

  // Filter according to Project Home
  if (projectHomes.length > 0) {
    const pattern = `{${projectHomes.join(',')},${projectHomes.join('/**,')}/**,}`
    rows = _.filter(rows, row => {
      // Always include projects that have been explicitly saved, even if their
      // paths aren't in Project Home
      if (row.provider === 'file') return true

      return row.paths.filter(
        minimatch.filter(pattern, {matchBase: true, dot: true})
      ).length > 0
    })
  }

  return rows
}

export function switchToProject (item) {
  return atomProjectUtil.switch(item.paths)
    .then(() => projectChangeNotification(item))
    .catch(err => { throw err })
}

function projectChangeNotification (item) {
  const name = `<strong>${getProjectTitle(item)}</strong>`

  let detail = null
  if (atom.config.get('project-plus.showPath')) {
    detail = item.paths.join('<br/>')
  }

  notificationManager.success(`Activated project ${name}`, {detail})
}

export function closeProject () {
  return atomProjectUtil.close()
}
