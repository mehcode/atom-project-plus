util = require '../lib/util'

describe "filterProjects", ->
  rows = [
    { project: { name: 1, paths: ['/Projects/', '/www/side'] } },
    { project: { name: 2, paths: ['/Projects/', '/next'] } },
    { project: { name: 3, paths: ['/tmp/Projects/'] } },
    { project: { name: 4, paths: ['/Projects/work/next'] } },
    { project: { name: 5, paths: ['/home/user/Projects'] } },
    { project: { name: 6, paths: ['/Projects/hobby'] } },
    { project: { name: 7, paths: ['/some/folder/here'] } },
    { project: { name: 8, paths: ['/Workspace/b', '/Workspace/c'] } },
    { project: { name: 9, paths: ['/Workspace.bak/a'] } },
  ]

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('project-plus')

  afterEach ->
    atom.config.set('project-plus.folderWhitelist', '')
    atom.config.set('project-plus.folderBlacklist', '')

  it "should return no projects when none match the whitelist", (done) ->
    atom.config.set('project-plus.folderWhitelist', 'exclude_all')
    util.filterProjects(rows).then (result) ->
      expect(result).toEqual([])

      done()

  it "should inlude only projects that match the whitelist", (done) ->
    atom.config.set('project-plus.folderWhitelist', '/some/folder/here')
    util.filterProjects(rows).then (result) ->
      expect(result.length).toEqual(1)
      expect(result[0].name).toEqual('here')

      done()

  it "should include projects that are within a whitelisted folder", (done) ->
    atom.config.set('project-plus.folderWhitelist', '/Projects')
    util.filterProjects(rows).then (result) ->
      expect(result.length).toEqual(4)

      atom.config.set('project-plus.folderWhitelist', '/Workspace')
      util.filterProjects(rows).then (result) ->
        expect(result.length).toEqual(1)

        done()

  it "should not include projects that match the blacklist", (done) ->
    atom.config.set('project-plus.folderBlacklist', '/some/folder/here')
    util.filterProjects(rows).then (result) ->
      expect(result.length).toEqual(9)

      util.filterProjects(rows).then (result) ->
        atom.config.set('project-plus.folderBlacklist', 'here')
        expect(result.length).toEqual(9)

        done()
