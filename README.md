<div align="center">

# only.nvim

[![Build Status](https://img.shields.io/github/actions/workflow/status/lima1909/only.nvim/ci.yaml?style=for-the-badge)](https://github.com/lima1909/only.nvim/actions)
![License](https://img.shields.io/github/license/lima1909/only.nvim?style=for-the-badge)
[![Stars](https://img.shields.io/github/stars/lima1909/only.nvim?style=for-the-badge)](https://github.com/lima1909/only.nvim/stargazers)

Filtering [plenary.nvim tests](https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md). Run `ONLY` the tests you want.

[Features](#features) • [Install](#install) • [Commands](#commands) • [Examples](#examples)

</div>

> [!NOTE]
>
> The project is still in development and can change. 


## Features

It's easy to run isolated tests in the current open buffer/file:

* per tags
* where the current cursor is located


## Install

- packer.nvim:

  ```lua
  use {
    "lima1909/only.nvim",
    requires = { "nvim-lua/plenary.nvim" },
  }
  ```

- lazy.nvim:

  ```lua
  {
    "lima1909/only.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  ```

  ## Commands

| User command                        | Description                                                      |
|-------------------------------------|------------------------------------------------------------------|
| `:OnlyBustedFile tags [your tags]`  | run all tests, which contains one of the tags in the description |
| `:OnlyBustedFile at_cursor`         | run all tests, which the cursor contains                         |

## Examples

### Tags: `thisone,other`

Command: `:OnlyBustedFile tags thisone,other`

```lua
describe("my group", function()
	it("first test, thisone", function() end)
	it("second test", function() end)
	it("third testi, other", function() end)
end)
```

Runs first and third test.
