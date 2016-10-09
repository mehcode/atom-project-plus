'use babel'

import {$, $$, SelectListView} from 'atom-space-pen-views'
import * as util from './util'
import tildify from 'tildify'
import providerManager from './provider-manager'
import notificationManager from './notification-manager'

let fuzzyFilter = null

export default
class ProjectPlusView extends SelectListView {
  constructor () {
    super()
    this.mode = null
  }

  initialize () {
    super.initialize()

    this.addClass('project-finder')

    atom.commands.add(this.element, {
      'project-finder:alt-open': () => {
        if (atom.config.get('project-plus.newWindow')) {
          this.open(null, false)
        } else {
          this.open(null, true)
        }
      }
    })
  }

  setMode (mode) {
    this.mode = mode
    return this
  }

  destroy () {
    this.cancel()

    if (this.panel) {
      this.panel.destroy()
    }

    if (this.subscriptions) {
      this.subscriptions.destroy()
      this.subscriptions = null
    }
  }

  show () {
    this.storeFocusedElement()

    this.panel = this.panel || atom.workspace.addModalPanel({item: this})
    this.panel.show()

    this.focusFilterEditor()
  }

  hide () {
    if (this.panel) this.panel.hide()
  }

  cancelled () {
    this.hide()
  }

  toggle () {
    if (this.panel && this.panel.isVisible()) {
      this.cancel()
    } else {
      this.populate()
      this.show()
    }
  }

  getFilterKey () {
    return 'title'
  }

  getEmptyMessage (itemCount) {
    return itemCount === 0 ? 'No saved projects' : super.getEmptyMessage()
  }

  viewForItem (item) {
    let showPath = atom.config.get('project-plus.showPath')

    return $$(function () {
      if (showPath) {
        this.li({class: 'two-lines'}, () => {
          this.div({class: 'primary-line'}, () => {
            this.text(item.title)
          })

          for (const pathname of item.paths) {
            this.div({class: 'secondary-line'}, () => {
              this.text(tildify(pathname))
            })
          }
        })
      } else {
        this.li({class: 'one-line'}, () => {
          this.div({class: 'primary-line'}, () => {
            this.text(item.title)
          })
        })
      }
    })
  }

  // Find all projects using the indexeddb backed state
  populate () {
    this.setLoading('Discovering projects\u2026')
    providerManager.all()
      .then(items => {
        items = util.sortProjects(items)
        this.setItems(items)
      })
      .catch(err => {
        console.error('Project Plus: Could not list projects:', err.stack)
        this.toggle()
        notificationManager.error('Project Plus: Could not list projects', {
          dismissable: true,
          stack: err.stack,
          description: 'Open the Dev Tools for more information, or file an issue ' +
            'on [Github](https://github.com/mehcode/atom-project-plus/issues/new).'
        })
      })
  }

  // Copy code from SelectListView so we can change to fuzzaldrin-plus
  populateList () {
    if (!this.items) return

    let filterQuery = this.getFilterQuery()
    let filteredItems = this.items
    if (filterQuery.length) {
      if (!fuzzyFilter) fuzzyFilter = require('fuzzaldrin-plus').filter
      filteredItems = fuzzyFilter(this.items, filterQuery, {key: this.getFilterKey()})
    }

    this.list.empty()
    if (filteredItems.length) {
      this.setError(null)

      filteredItems = filteredItems.slice(0, this.maxItems)
      for (let item of filteredItems) {
        let itemView = $(this.viewForItem(item))
        itemView.data('select-list-item', item)
        this.list.append(itemView)
      }

      this.selectItemView(this.list.find('li:first'))
    } else {
      this.setError(this.getEmptyMessage(this.items.length))
    }
  }

  confirmed (item) {
    if (this.mode === 'open') {
      this.open(item)
    } else {
      this.remove(item)
    }
  }

  open (item, newWindow) {
    if (!item) item = this.getSelectedItem()
    if (!newWindow) newWindow = atom.config.get('project-plus.newWindow')
    this.hide()

    if (newWindow) {
      // Open project in new window
      atom.open({pathsToOpen: item.paths, newWindow: true})
    } else {
      // Switch to project in the same window
      util.switchToProject(item)
    }
  }

  remove (item) {
    this.hide()

    // Remove projects from providers
    providerManager.remove(item.paths)
  }
}
