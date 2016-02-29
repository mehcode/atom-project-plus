{CompositeDisposable} = require "atom"
util = require "./util"

module.exports = ProjectPlus =
  projectPlusView: null
  modalPanel: null
  subscriptions: null

  config:
    folderWhitelist:
      type: 'string'
      default: ''
      title: 'Folder Whitelist'
      description: 'you can specify list of whitelisted folders, separated by comma. e.g ~/Projects/Work, ~/Projects/hobby'
    folderBlacklist:
      type: 'string'
      default: ''
      title: 'Folder Blacklist'
      description: 'you can specify list of blacklisted folders, separated by comma. e.g ~/Projects/Work/secret, ~/Projects/hob by/new'

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
