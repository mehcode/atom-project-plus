{CompositeDisposable} = require "atom"
util = require "./util"

module.exports = ProjectPlus =
  projectPlusView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # @projectPlusView = new ProjectPlusView(state.projectPlusViewState)
    # @modalPanel = atom.workspace.addModalPanel(item: @projectPlusView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add "atom-workspace",
      "project-plus:open": =>
        @getProjectFinder().setMode("open").toggle()
      "project-plus:switch": =>
        @getProjectFinder().setMode("switch").toggle()
      "project-plus:remove": =>
        @getProjectFinder().setMode("remove").toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @projectPlusView.destroy()

  serialize: ->

  getProjectFinder: ->
    unless @projectFinderView?
      ProjectFinderView = require "./project-finder-view"
      @projectFinderView = new ProjectFinderView()

    @projectFinderView
