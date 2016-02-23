exports.saveCurrentState = () ->
  # Serialize the current atom environment
  # TODO: This is in two places now
  currentState = atom.serialize()
  currentKey = atom.getStateKey(atom.project.getPaths())

  if currentKey
    window.atom.stateStore.save(currentKey, currentState)

  else
    Promise.resolve(null)
