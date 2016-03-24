util = require '../lib/util'

describe "filterProjects", ->
  rows = [
    { title: 1, paths: ['/Projects/', '/www/side'] },
    { title: 2, paths: ['/Projects/', '/next'] },
    { title: 3, paths: ['/tmp/Projects/'] },
    { title: 4, paths: ['/Projects/work/next'] },
    { title: 5, paths: ['/home/user/Projects'] },
    { title: 6, paths: ['/Projects/hobby'] },
    { title: 7, paths: ['/some/folder/here'] },
    { title: 8, paths: ['/Workspace/b', '/Workspace/c'] },
    { title: 9, paths: ['/Workspace.bak/a'] },
    { title: 10, paths: ['/Workspace.bak/.git/secret'] },
  ]

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('project-plus')

  afterEach ->
    atom.config.set('project-plus.projectHome', '')

  it "should return no projects when none match the whitelist", ->
    atom.config.set('project-plus.projectHome', 'exclude_all')
    expect(util.filterProjects(rows)).toEqual([])

  it "should inlude only projects that match the whitelist", ->
    atom.config.set('project-plus.projectHome', '/some/folder/here')
    expect(util.filterProjects(rows).length).toEqual(1)

  it "should include projects that are within a whitelisted folder", ->
    atom.config.set('project-plus.projectHome', '/Projects')
    expect(util.filterProjects(rows).length).toEqual(4)

    atom.config.set('project-plus.projectHome', '/Workspace')
    expect(util.filterProjects(rows).length).toEqual(1)

  it "should filter out projects that don't make sense", ->
    items = [
      # No paths array
      {},
      # No paths
      {paths: []},
      # 1 path but it contains something weird
      {paths: [2]},
      # Something okay here
      {paths: ["/work"]}
    ]

    expect(util.filterProjects(items).length).toEqual(1)
