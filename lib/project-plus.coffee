{CompositeDisposable} = require "atom"
util = require "./util"

module.exports = ProjectPlus =
  projectPlusView: null
  modalPanel: null
  subscriptions: null

  config:
    folderBlacklist:
      type: 'string'
      default: ''
      title: 'Folder Blacklist'
      description: 'Projects will never be shown for paths matching this list (including subpaths), eg `$HOME/Documents` to exclude a single folder and all its children.'
    folderWhitelist:
      type: 'string'
      default: ''
      title: 'Folder Whitelist'
      description: 'Projects will only be shown for paths matching this list (including subpaths), eg `$HOME/Workspace` to limit to a single folder and all its children.'

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add "atom-workspace",
      "project-plus:toggle-project-finder": =>
        @getProjectFinder().toggle()

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
