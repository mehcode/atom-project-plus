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
            if atom.config.get('project-plus.newWindow')
              atom.open(pathsToOpen: selectedPaths, newWindow: true)
            else
              util.switchToProject({paths: selectedPaths})

      "project-plus:close": =>
        util.closeProject()

      "project-plus:save": =>
        providerManager.save(atom.project.getPaths())

      "project-plus:toggle-project-finder": =>
        # Remove project from available providers
        @getProjectFinder().setMode("open").toggle()

      "project-plus:open-next-recently-used-project": =>
        @getProjectTab().next()

      "project-plus:open-previous-recently-used-project": =>
        @getProjectTab().previous()

      "project-plus:move-active-project-to-top-of-stack": =>
        # Clear the tab index
        @projectTab = null

      "project-plus:edit-projects": =>
        # Open the projects.cson
        atom.workspace.open(require("./provider/file").getFile())

      "project-plus:remove": =>
        # Remove project from available providers
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

  getProjectTab: ->
    unless @projectTab
      ProjectTab = require "./project-tab"
      @projectTab = new ProjectTab()

    @projectTab
