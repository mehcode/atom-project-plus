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
    { project: { name: 10, paths: ['/Workspace.bak/.git/secret'] } },
  ]

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('project-plus')

  afterEach ->
    atom.config.set('project-plus.folderWhitelist', '')
    atom.config.set('project-plus.folderBlacklist', '')

  it "should return no projects when none match the whitelist", ->
      atom.config.set('project-plus.folderWhitelist', 'exclude_all')
      expect(util.filterProjects(rows)).toEqual([])

  it "should inlude only projects that match the whitelist", ->
      atom.config.set('project-plus.folderWhitelist', '/some/folder/here')
      expect(util.filterProjects(rows).length).toEqual(1)

  it "should include projects that are within a whitelisted folder", ->
      atom.config.set('project-plus.folderWhitelist', '/Projects')
      expect(util.filterProjects(rows).length).toEqual(4)

      atom.config.set('project-plus.folderWhitelist', '/Workspace')
      expect(util.filterProjects(rows).length).toEqual(1)

  it "should not include projects that match the blacklist", ->
      atom.config.set('project-plus.folderBlacklist', '/some/folder/here')
      expect(util.filterProjects(rows).length).toEqual(rows.length - 1)

      atom.config.set('project-plus.folderBlacklist', 'here')
      expect(util.filterProjects(rows).length).toEqual(rows.length - 1)

  it "should not include projects that match glob pattern in blacklist", ->
    atom.config.set('project-plus.folderBlacklist', '/**/.git/**')
    expect(util.filterProjects(rows).length).toEqual(rows.length - 1)

    atom.config.set('project-plus.folderBlacklist', '/Workspace.bak/.git/**')
    expect(util.filterProjects(rows).length).toEqual(rows.length - 1)
