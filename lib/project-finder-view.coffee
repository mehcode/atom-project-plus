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
    # TODO: Cache?

    @setLoading("Discovering projects\u2026")

    window.atom.stateStore.dbPromise
      .then (db) =>
        return new Promise (resolve, reject) =>
          store = db.transaction(['states']).objectStore('states')
          request = store.openCursor()
          rows = []

          request.onerror = (event) => reject(event)
          request.onsuccess = (event) =>
            cursor = event.target.result
            if cursor
              rows.push cursor.value
              cursor.continue()

            else
              resolve(rows)

      .then (rows) =>
        items = rows.map (row) =>
          # NOTE: Currently the name of the project
          #       is just set to the first path's basename
          name: path.basename(row.value.project.paths[0])
          paths: row.value.project.paths

        items = _.filter items, (item) =>
          not _.isEqual(item.paths, atom.project.getPaths())

        # Unique project listing
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

        # Compute new state key from paths
        newKey = atom.getStateKey(item.paths)

        # Save the state of the current project
        util.saveCurrentState().then () =>
          # Load the state of the new project
          window.atom.stateStore.load(newKey).then (state) =>
            atom.deserialize(state)

            # TODO: These are areas where we should submit PRs to
            #       open functionality for it

            # HACK: Tree view doesn't reload expansion states
            tvState = state.packageStates["tree-view"]
            if tvState
              treeViewPack = atom.packages.getActivePackage("tree-view")
              tv = treeViewPack?.mainModule?.treeView
              if tv
                tv.attach() unless tv.isVisible()
                tv.updateRoots(tvState.directoryExpansionStates)
                tv.selectEntry(tv.roots[0])
                tv.selectEntryForPath(tvState.selectedPath) if tvState.selectedPath
                tv.focus() if tvState.hasFocus
                tv.scroller.scrollLeft(tvState.scrollLeft) if tvState.scrollLeft > 0
                tv.scrollTop(tvState.scrollTop) if tvState.scrollTop > 0
