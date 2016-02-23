# PLEASE NOTE, THIS PACKAGE CURRENTLY DEPENDS ON https://github.com/atom/atom/pull/10605
## This package should work on atom 1.7.x+

---

# Project Plus
> Simply awesome project management in Atom.

You may be thinking.. Yet another project manager (for atom)? Atom contains a
lot of piping to make project management awesome. It's missing those few bits
that expose that awesome to users. This is that package.

 - **No configuration** — atom was already keeping track of your projects

 - **No mess** (project files) — atom already knows about your projects and their needs (and is planning to know more)

 - **No weirdness** — switching between projects (in the same window) is done correctly and does not corrupt state (unlike every existing project package I've seen)

 - Fully supports projects with multiple paths

## Installation

```
apm install project-plus
```

## Commands
All commands (except `:close`) open up your list of projects to select the target for the action.

Command                | Description
-----------------------|-------------
`project-plus:switch`  | Switch to project in the same window (correctly)
`project-plus:open`    | Open project in a new window
`project-plus:close`   | Close project (as if you opened atom without a directory and without existing state)
`project-plus:remove`  | Remove project from atom (this does not delete files; it only makes atom forget that you've opened the folder before)

## Keybindings
There are none (yet). Suggestions are welcome.

## Contributing

Always feel free to help out!  Whether it's filing bugs and feature requests
or working on some of the open issues, Atom's [contributing guide](https://github.com/atom/atom/blob/master/CONTRIBUTING.md)
will help get you started while the [guide for contributing to packages](https://github.com/atom/atom/blob/master/docs/contributing-to-packages.md)
has some extra information.

## License

[MIT License](http://opensource.org/licenses/MIT) - see the [LICENSE](https://github.com/mehcode/atom-project-plus/blob/master/LICENSE.md) for more details.
