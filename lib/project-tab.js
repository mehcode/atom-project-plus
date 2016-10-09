'use babel'

import _ from 'underscore-plus'
import * as util from './util'
import providerManager from './provider-manager'

export default
class ProjectTab {
  constructor () {
    // Get the current list of projects
    this.promise = new Promise((resolve) => {
      util.saveCurrentState().then(() => {
        providerManager.all({excludeCurrent: false}).then((projects) => {
          this.projects = util.sortProjects(projects)

          // We are currently at what ..
          const currentPaths = atom.project.getPaths()
          let currentIndex = -1
          for (let index = 0; index < projects.length; ++index) {
            if (_.isEqual(projects[index].paths, currentPaths)) {
              currentIndex = index
              break
            }
          }

          this.index = currentIndex
          resolve()
        })
      })
    })
  }

  move (offset) {
    // Ensure that you can't tab while we're tabbing
    if (this.inProgress) return
    this.inProgress = true

    this.promise.then(() => {
      // If we have only 1 project -- do nothing
      if (this.projects.length === 1) return

      let nextIndex = this.index + offset
      if (nextIndex >= this.projects.length) {
        nextIndex = 0
      } else if (nextIndex < 0) {
        nextIndex = this.projects.length - 1
      }

      this.index = nextIndex

      // Switch
      util.switchToProject(this.projects[this.index]).then(() => {
        // Done
        this.inProgress = false
      })
    })
  }

  next () {
    this.move(1)
  }

  previous () {
    this.move(-1)
  }
}
