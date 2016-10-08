'use babel'

import git from 'git-utils'
import { getProjectTitle, getIcon } from '../util'

class Project {

  constructor ({ paths, provider, timestamp, title, icon }) {
    this.paths = paths
    this.provider = provider
    this.timestamp = timestamp
    this.icon = getIcon(icon || 'repo')
    this.title = title || getProjectTitle(this)
    this.dirty = null
    this.branch = null

    this.readGitInfo()
  }

  hasGitInfo () {
    return (this.dirty != null) && (this.branch != null)
  }

  readGitInfo () {
    return new Promise((resolve, reject) => {
      // If there is more than one path, git information will be shown for the
      // first. Either we disable multi-path git info, or make it a config.
      const repository = git.open(this.paths[0])

      if (repository) {
        const branch = repository.getShortHead()
        const dirty = Object.keys(repository.getStatus()).length !== 0
        const info = {branch, dirty}

        this.setGitInfo(info)
        repository.release()

        resolve(info)
      } else {
        resolve()
      }
    })
  }

  setGitInfo ({branch, dirty}) {
    this.branch = branch
    this.dirty = dirty
  }

}

export default Project
