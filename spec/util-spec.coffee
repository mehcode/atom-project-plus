util = require '../lib/util'

describe "when a test is written", ->
  rows = [
    { project: { name: 1, paths: ['/Projects/', '/www/side'] } },
    { project: { name: 2, paths: ['/Projects/', '/next'] } },
    { project: { name: 3, paths: ['/tmp/Projects/'] } },
    { project: { name: 4, paths: ['/Projects/work/next'] } },
    { project: { name: 5, paths: ['/home/user/Projects'] } },
    { project: { name: 6, paths: ['/Projects/hobby'] } },
    { project: { name: 7, paths: ['/some/folder/here'] } }
  ]

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('project-plus')

  afterEach ->
    atom.config.set('project-plus.folderWhitelist', '')
    atom.config.set('project-plus.folderBlacklist', '')

  it "filters all projects when no matches with Whitelist", ->
    atom.config.set('project-plus.folderWhitelist', 'exclude_all')
    expect(util.sanitize(rows)).toEqual([])

  it "should filtered out all projects exept one in a whitelist", ->
    atom.config.set('project-plus.folderWhitelist', '/some/folder/here')
    expect(util.sanitize(rows).length).toEqual(1)
    expect(util.sanitize(rows)[0].name).toEqual('here')

  it "returns all project in a whitelisted subfolder", ->
    atom.config.set('project-plus.folderWhitelist', '/Projects')
    expect(util.sanitize(rows).length).toEqual(6)

  it "returns all projects exept blacklisted", ->
    atom.config.set('project-plus.folderBlacklist', '/some/folder/here')
    expect(util.sanitize(rows).length).toEqual(6)
    atom.config.set('project-plus.folderBlacklist', 'here')
    expect(util.sanitize(rows).length).toEqual(6)
