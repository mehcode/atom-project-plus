ProjectPlusView = require './project-plus-view'
{CompositeDisposable} = require 'atom'

module.exports = ProjectPlus =
  projectPlusView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @projectPlusView = new ProjectPlusView(state.projectPlusViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @projectPlusView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'project-plus:toggle-project-finder': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @projectPlusView.destroy()

  serialize: ->
    projectPlusViewState: @projectPlusView.serialize()

  toggle: ->
    console.log 'ProjectPlus was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
