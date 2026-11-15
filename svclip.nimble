# Package

version       = "0.1.0"
author        = "Gellei Csaba"
description   = "Save clipboard in terminal"
license       = "GPL-2.0-or-later"
srcDir        = "src"
bin           = @["svclip"]


# Dependencies

requires "nim >= 2.2.10"
requires "db_connector"
requires "libclip"
