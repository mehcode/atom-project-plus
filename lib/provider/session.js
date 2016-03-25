'use babel'

import _ from 'underscore-plus'
import async from 'async'
import fs from 'fs-plus'
import path from 'path'

import util from '../util'

export function saveState (paths) {
  // Compute state key from path set
  const key = atom.getStateKey(paths)
  if (!key) return Promise.resolve(null)

  // Serialize state
  const state = util.atomSerialize()

  if (atom.stateStore != null) {
    // Atom 1.7+
    return atom.stateStore.save(key, state)
  } else {
    // Atom 1.5 to 1.6
    const store = util.atomGetStorageFolder()
    const keypath = store.pathForKey(key)
    return new Promise((resolve, reject) => {
      fs.writeFile(keypath, JSON.stringify(state), 'utf8', (err) => {
        if (err) return reject(err)
        resolve()
      })
    })
  }
}

// Session provider discovers projects by inspecting atom's session
// state; in other words, any previously opened projects would get discovered
// here

function findFromIndexedDB () {
  return new Promise((resolve, reject) => {
    // Do nothing if not Atom 1.7+
    if (atom.stateStore == null) return resolve([])

    // Atom 1.7+
    // We have state serialized to IndexedDB
    atom.stateStore.dbPromise.then((db) => {
      const store = db.transaction(['states']).objectStore('states')
      const request = store.openCursor()
      let rows = []

      request.onerror = (event) => reject(event)
      request.onsuccess = (event) => {
        const cursor = event.target.result
        if (cursor) {
          rows.push(cursor.value)
          cursor.continue()
        } else {
          // Map to ensure we have 100% JSON
          rows = rows.map((row) => {
            // Either actual JSON is stored or a JSON serialization
            let result = row.value
            if (typeof result === 'string' && row.isJSON) {
              result = JSON.parse(row.value)
            }

            result.updatedAt = new Date(Date.parse(row.storedAt))
            return result
          }).filter((row) => {
            // Filter to ensure we have a project object
            return row.project != null
          }).map((row) => {
            // Convert to the common format
            return {
              paths: row.project.paths,
              timestamp: row.updatedAt,
              provider: 'session'
            }
          })

          resolve(rows)
        }
      }
    })
  })
}

function findFromStorageFolder () {
  return new Promise((resolve, reject) => {
    // Atom 1.5 to 1.6
    // Editor state is in a storage folder
    const storageFolder = util.atomGetStorageFolder().path

    // List the storage folder
    fs.list(storageFolder, (err, filenames) => {
      if (err) return reject(err)

      // Filter to only have filenames that start with editor-
      filenames = _.filter(filenames, (fn) => {
        const basename = path.basename(fn)
        return /^editor-/.test(basename)
      })

      // Read in the JSON data from each state file
      async.map(filenames, (filename, cb) => {
        fs.stat(filename, (err, stats) => {
          if (err) return cb(err)

          const updatedAt = new Date(Date.parse(stats.mtime))

          fs.readFile(filename, 'utf8', (err, data) => {
            if (err) return cb(err)

            const item = JSON.parse(data)
            const row = {
              paths: item.project.paths,
              timestamp: updatedAt,
              provider: 'file'
            }

            cb(null, row)
          })
        })
      }, (err, rows) => {
        if (err) return reject(err)
        resolve(rows)
      })
    })
  })
}

export default class SessionProvider {
  all () {
    return new Promise((resolve, reject) => {
      Promise.all([
        findFromIndexedDB(),
        findFromStorageFolder()
      ]).then((results) => {
        resolve(_.flatten(results))
      }).catch(reject)
    })
  }

  save (paths) {
    return saveState(paths)
  }
}
