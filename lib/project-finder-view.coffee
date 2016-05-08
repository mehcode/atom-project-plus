_ = require "underscore-plus"
path = require "path"
url = require "url"
{$, $$, SelectListView} = require "atom-space-pen-views"
util = require "./util"
tildify = require "tildify"
providerManager = require "./provider-manager"

module.exports =
class ProjectPlusView extends SelectListView
  mode: null

  initialize: ->
    super

    @addClass("project-finder")

    atom.commands.add @element,
      'project-finder:alt-open': =>
        if atom.config.get('project-plus.newWindow')
          @open(null, false)
        else @open(null, true)

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
    'title'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      "No saved projects"
    else
      super

  viewForItem: (item) ->
    showPath = atom.config.get('project-plus.showPath')

    $$ ->
      if showPath
        @li class: 'two-lines', =>
          @div class: "primary-line", =>
            @text item.title

          for pathname in item.paths
            @div class: "secondary-line", =>
              @text tildify(pathname)
      else
        @li class: 'one-line', =>
          @div class: "primary-line", =>
            @text item.title

  # Find all projects using the indexeddb backed state
  populate: ->
    @setLoading("Discovering projects\u2026")
    providerManager.all().then (items) =>
      items = util.sortProjects(items)
      @setItems items

  confirmed: (item) -> @open(item)

  open: (item, newWindow) ->
    item ?= @getSelectedItem()
    newWindow ?= atom.config.get('project-plus.newWindow')
    @hide()

    if newWindow # Open project in new window
      atom.open(pathsToOpen: item.paths, newWindow: true)
    else
      # Switch to project in the same window
      util.switchToProject item
