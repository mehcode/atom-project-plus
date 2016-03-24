{CompositeDisposable} = require "atom"
util = require "./util"
providerManager = require "./provider-manager"

module.exports = ProjectPlus =
  projectPlusView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Register project providers
    providerManager.addProvider("session")
    providerManager.addProvider("file")

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add "atom-workspace",
      "project-plus:open": =>
        atom.pickFolder (selectedPaths = []) =>
          if selectedPaths
            util.switchToProject({paths: selectedPaths})

      "project-plus:close": =>
        util.closeProject()

      "project-plus:save": =>
        providerManager.save(atom.project.getPaths())

      "project-plus:toggle-project-finder": =>
        @getProjectFinder().toggle()

      "project-plus:open-next-recently-used-project": =>
        @getProjectTab().next()

      "project-plus:open-previous-recently-used-project": =>
        @getProjectTab().previous()

      "project-plus:move-active-project-to-top-of-stack": =>
        # Clear the tab index
        @projectTab = null

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

  getProjectTab: ->
    unless @projectTab
      ProjectTab = require "./project-tab"
      @projectTab = new ProjectTab()

    @projectTab
