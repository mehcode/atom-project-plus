'use babel'

import {CompositeDisposable} from 'atom'
import * as util from './util'
import providerManager from './provider-manager'

class ProjectPlus {
  constructor () {
    this.subscriptions = null
  }

  activate (state) {
    // Register project providers
    providerManager.addProvider('session')
    providerManager.addProvider('file')

    // Events subscribed to in atom's system can be easily cleaned up
    // with a CompositeDisposable
    this.subscriptions = new CompositeDisposable()

    // Register commands
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'project-plus:open': () => {
        atom.pickFolder((selectedPaths = []) => {
          if (selectedPaths) {
            if (atom.config.get('project-plus.newWindow')) {
              atom.open({pathsToOpen: selectedPaths, newWindow: true})
            } else {
              util.switchToProject({paths: selectedPaths})
            }
          }
        })
      },

      'project-plus:close': () => {
        util.closeProject()
      },

      'project-plus:save': () => {
        providerManager.save(atom.project.getPaths())
      },

      'project-plus:toggle-project-finder': () => {
        // Remove project from available providers
        this.getProjectFinder().setMode('open').toggle()
      },

      'project-plus:open-next-recently-used-project': () => {
        this.getProjectTab().next()
      },

      'project-plus:open-previous-recently-used-project': () => {
        this.getProjectTab().previous()
      },

      'project-plus:move-active-project-to-top-of-stack': () => {
        // Clear the tab index
        this.projectTab = null
      },

      'project-plus:edit-projects': () => {
        // Open the projects.cson
        atom.workspace.open(require('./provider/file').getFile())
      },

      'project-plus:remove': () => {
        // Remove project from available providers
        this.getProjectFinder().setMode('remove').toggle()
      }
    }))
  }

  deactivate () {
    this.subscriptions.dispose()
    if (!!this.projectFinderView) {
      this.projectFinderView.destroy();
    }
  }

  serialize () {}

  getProjectFinder () {
    if (!this.projectFinderView) {
      const ProjectFinderView = require('./project-finder-view')
      this.projectFinderView = new ProjectFinderView()
    }

    return this.projectFinderView
  }

  getProjectTab () {
    if (!this.projectTab) {
      const ProjectTab = require('./project-tab')
      this.projectTab = new ProjectTab()
    }

    return this.projectTab
  }
}

export default new ProjectPlus()
