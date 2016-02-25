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

    atom.commands.add @element,
      'project-finder:open-in-new-window': =>
        @confirmAndOpenInNewWindow()

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

    # Switch to project in the same window
    util.switchToProject item

  confirmAndOpenInNewWindow: () ->
    item = @getSelectedItem()
    @hide()

    # Open project in new window
    # TODO: `newWindow: false` means reuse existing window if possible (
    #         might want a config option here)
    atom.open(pathsToOpen: item.paths, newWindow: false)
