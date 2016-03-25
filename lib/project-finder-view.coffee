_ = require "underscore-plus"
path = require "path"
url = require "url"
{$, $$, SelectListView} = require "atom-space-pen-views"
util = require "./util"
tildify = require "tildify"
fuzzaldrinPlus = require "fuzzaldrin-plus"
providerManager = require "./provider-manager"

fuzzyFilter = null;

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

  # Copy code from SelectListView so we can change to fuzzaldrin-plus
  populateList: ->
    return unless @items?

    filterQuery = @getFilterQuery()
    if filterQuery.length
      fuzzyFilter ?= require('fuzzaldrin-plus').filter
      filteredItems = fuzzyFilter(@items, filterQuery, key: @getFilterKey())
    else
      filteredItems = @items

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(@items.length, filteredItems.length))

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
