_ = require "underscore-plus"
path = require "path"
url = require "url"
{$, $$, SelectListView} = require "atom-space-pen-views"
util = require "./util"

module.exports =
class ProjectPlusView extends SelectListView
  mode: null

  initialize: ->
    super

    @addClass("project-finder")

  destroy: ->
    @cancel()
    @panel?.destroy()
    @subscriptions?.dispose()
    @subscriptions = null

  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  cancelled: ->
    @hide()

  setMode: (mode) ->
    @mode = mode
    this

  toggle: ->
    if @panel?.isVisible()
      @cancel()
    else
      @populate()
      @show()

  getFilterKey: ->
    'name'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      "No saved projects"
    else
      super

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: "primary-line", =>
          @text item.name

        @div class: "secondary-line", =>
          @text item.paths[0]

  # Find all projects using the indexeddb backed state
  populate: ->
    @setLoading("Discovering projects\u2026")
    util.findProjects().then (items) =>
      @setItems items

  confirmed: (item) ->
    @hide()

    switch @mode
      when "open"
        # Open project in new window
        # TODO: `newWindow: false` means reuse existing window if possible (
        #         might want a config option here)
        atom.open(pathsToOpen: item.paths, newWindow: false)

      when "remove"
        # Remove project from atom's serialized state

        # Compute state key from paths
        key = atom.getStateKey(item.paths)

        # Remove key from store
        window.atom.stateStore.dbPromise.then (db) =>
          store = db.transaction(['states'], "readwrite").objectStore('states')
          request = store.delete(key)

      when "switch"
        # Switch to project in the same window
        util.switchToProject item
