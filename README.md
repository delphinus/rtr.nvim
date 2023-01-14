# rtr.nvim

Simple & small implementation for chdir'ing accordingly

## What's this?

This is a yet another plugin to change the current directory according to the file on each buffer. There are similar plugins: [airblade/vim-rooter][], [ahmedkhalf/project.nvim][], but **rtr.nvim** has the most simple implementation to achieve the same feature with using `vim.fs.find` API.

[airblade/vim-rooter]: https://github.com/airblade/vim-rooter
[ahmedkhalf/project.nvim]: https://github.com/ahmedkhalf/project.nvim

## Install & Usage

### packer.nvim

```lua
use {
  "delphinus/rtr.nvim",
  config = function()
    require("rtr").setup {}
  end,
}
```

### lazy.nvim

```lua
require("lazy").setup {
  { "delphinus/rtr.nvim", config = true },
}
```

Just done. Simple!

See more detail usage in [doc](doc/rtr.txt).

## Caveats

This plugin needs `vim.fs.find` to work. You chould use newer Neovim (>= 0.8.2).
