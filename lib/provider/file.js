'use babel'

import _ from 'underscore-plus'
import fs from 'fs-plus'
import path from 'path'
import CSON from 'season'

// The file format is intended to be compatible with project-manager

export function getFile () {
  const filename = 'projects.cson'
  const dir = atom.getConfigDirPath()

  return path.join(dir, filename)
}

function readFile () {
  const filename = getFile()
  return new Promise((resolve, reject) => {
    fs.exists(filename, (exists) => {
      if (!exists) return resolve({})

      CSON.readFile(filename, (err, result) => {
        if (err) return reject(err)
        if (!result) result = {}

        // Projects are stored as an object where the key is the title
        // This feels a bit odd to me
        // TODO: Ask @danielbrodin about it
        return resolve(result)
      })
    })
  })
}

function writeFile (projects) {
  return new Promise((resolve, reject) => {
    CSON.writeFile(getFile(), projects, (err) => {
      if (err) return reject(err)
      resolve()
    })
  })
}

export default class FileProvider {
  all () {
    return new Promise((resolve, reject) => {
      readFile().then((items) => {
        // Projects are stored as an object where the key is the title
        // That seems a bit odd to me; why not an array?
        items = _.values(items)

        // Add provider
        for (let item of items) {
          item.provider = 'file'
        }

        resolve(items)
      }, reject)
    })
  }

  getID (paths) {
    // Calculate a title (as this is needed for a save)
    // TODO: Allow a custom title
    let id = paths.map((pn) => path.basename(pn)).join(',\u00a0')
    // REF: https://github.com/danielbrodin/atom-project-manager/blob/master/lib/db.js#L162
    id = id.replace(/\s+/g, '').toLowerCase()

    return id
  }

  save (paths) {
    const id = this.getID(paths)

    return new Promise((resolve, reject) => {
      readFile().then((items) => {
        // Add the updated project into the items array
        items[id] = _.extend(items[id] || {}, {title: id, paths})

        // Write out the file
        writeFile(items).then(resolve, reject)
      }, reject)
    })
  }

  remove (paths) {
    const id = this.getID(paths)

    return new Promise((resolve, reject) => {
      readFile().then((items) => {
        // Remove the project
        delete items[id]

        // Write out the file
        writeFile(items).then(resolve, reject)
      }, reject)
    })
  }
}
