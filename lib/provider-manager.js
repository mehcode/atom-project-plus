"use babel";

import _ from "underscore-plus";

import util from "./util";

class ProviderManager {
  constructor() {
    this.providers = {};
  }

  getProviders() {
    return _.values(this.providers);
  }

  // Add a new project provider
  addProvider(key) {
    const cls = require("./provider/" + key);
    this.providers[key] = new cls();
  }

  removeProvider(key) {
    delete this.providers[key];
  }

  invoke(method, arguments_=[]) {
    return new Promise((resolve, reject) => {
      Promise.all(this.getProviders().map((p) => {
        return p[method].apply(p, arguments_);
      })).then((results) => {
        resolve(_.flatten(results));
      }).catch(reject);
    });
  }

  // Find all projects; regardless of package configuration (filter, etc.)
  all() {
    return new Promise((resolve) => {
      this.invoke("all").then((items) => {
        // De-duplicate by merging together all duplicate items
        // This has the lovely bonus of adding timestamps to
        // projects.cson - provided projects
        let result = {};
        for (let item of items) {
          let key = atom.getStateKey(item.paths);
          result[key] = _.extend(result[key] || {}, item);
        }

        result = _.values(result);

        // Filter
        result = util.filterProjects(result)

        resolve(result);
      });
    });
  }

  // Save a new project so that `all` will subsequently return it
  save(paths) {
    return this.invoke("save", [paths]);
  }
}

export default new ProviderManager();
