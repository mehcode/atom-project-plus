'use babel'

import sinon from 'sinon'
import fuzzaldrin from 'fuzzaldrin-plus'
import * as util from '../lib/util'

// Stub fuzzaldrin score.
fuzzaldrin.score = sinon.stub()

describe('filterProjects', () => {
  let rows = [
    { title: 1, paths: ['/Projects/', '/www/side'] },
    { title: 2, paths: ['/Projects/', '/next'] },
    { title: 3, paths: ['/tmp/Projects/'] },
    { title: 4, paths: ['/Projects/work/next'] },
    { title: 5, paths: ['/home/user/Projects'] },
    { title: 6, paths: ['/Projects/hobby'] },
    { title: 7, paths: ['/some/folder/here'] },
    { title: 8, paths: ['/Workspace/b', '/Workspace/c'] },
    { title: 9, paths: ['/Workspace.bak/a'] },
    { title: 10, paths: ['/Workspace.bak/.git/secret'] }
  ]

  beforeEach(() =>
    waitsForPromise(() => atom.packages.activatePackage('project-plus'))
  )

  afterEach(() => atom.config.set('project-plus.projectHome', ''))

  it('should return no projects when none match the whitelist', () => {
    atom.config.set('project-plus.projectHome', 'exclude_all')
    expect(util.filterProjects(rows)).toEqual([])
  })

  it('should inlude only projects that match the whitelist', () => {
    atom.config.set('project-plus.projectHome', '/some/folder/here')
    expect(util.filterProjects(rows).length).toEqual(1)
  })

  it('should include projects that are within a whitelisted folder', () => {
    atom.config.set('project-plus.projectHome', '/Projects')
    expect(util.filterProjects(rows).length).toEqual(4)

    atom.config.set('project-plus.projectHome', '/Workspace')
    expect(util.filterProjects(rows).length).toEqual(1)
  })

  it('should always include projects that have been saved', () => {
    const items = rows.slice(0)
    items.push({ title: 11, paths: ['outside_of_home'], provider: 'file' })

    atom.config.set('project-plus.projectHome', '/Projects')
    expect(util.filterProjects(items).length).toEqual(5)
  })

  it("should filter out projects that don't make sense", () => {
    const items = [
      // No paths array
      {},
      // No paths
      {paths: []},
      // 1 path but it contains something weird
      {paths: [2]},
      // Something okay here
      {paths: ['/work']}
    ]

    expect(util.filterProjects(items).length).toEqual(1)
  })
})

describe('fuzzyFilterItems', () => {
  let items = [
    {title: 'side', paths: ['/www/side', '/Projects/side']},
    {title: 'next', paths: ['/www/next', '/Projects/next']}
  ]

  it('should weight title matches 4 times more than paths', () => {
    fuzzaldrin.score.returns(1)
    const filtered = util.fuzzyFilterItems(items, '')
    expect(filtered[0].score).toEqual(5)
  })

  it('should filter out items whose score is 0', () => {
    fuzzaldrin.score.withArgs('side', '').returns(0)
    fuzzaldrin.score.withArgs('/www/side:/Projects/side', '').returns(0)
    fuzzaldrin.score.withArgs('next', '').returns(1)
    fuzzaldrin.score.withArgs('/www/next:/Projects/next', '').returns(1)

    const filtered = util.fuzzyFilterItems(items, '')
    expect(filtered.length).toEqual(1)
  })

  it('should sort items by their score', () => {
    fuzzaldrin.score.withArgs('side', '').returns(5)
    fuzzaldrin.score.withArgs('/www/side:/Projects/side', '').returns(5)
    fuzzaldrin.score.withArgs('next', '').returns(10)
    fuzzaldrin.score.withArgs('/www/next:/Projects/next', '').returns(10)

    const filtered = util.fuzzyFilterItems(items, '')
    expect(filtered[0]).toEqual(items[1])
    expect(filtered[1]).toEqual(items[0])
  })
})
