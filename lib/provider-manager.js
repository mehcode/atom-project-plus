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
        // Filter
        items = util.filterProjects(items)

        // De-duplicate
        items = _.uniq(items, (item) => {
          return item.paths.sort().join("");
        });

        resolve(items);
      });
    });
  }

  // Save a new project so that `all` will subsequently return it
  save(paths) {
    return this.invoke("save", [paths]);
  }
}

export default new ProviderManager();
