
from libqtile.command import lazy
from libqtile.config import Group, Key


# the 12 keys in the number row of the keyboard
_groupKeys = [str(key) for key in range(1, 9) + [0, '-', '+']]

# 24 groups for the above keys with and without control
groups = [
    Group(mod + key)
    for key in _groupKeys
    for mod in ['', '^']
]



_mod = "mod4"

keys = [
    Key([_mod], "j", lazy.layout.up()),
    Key([_mod], "k", lazy.layout.down()),

    Key([_mod, "shift"], "j", lazy.layout.shuffle_up()),
    Key([_mod, "shift"], "k", lazy.layout.shuffle_down()),

    Key([_mod], "Space", lazy.layout.next()),

    Key([_mod], "Escape", lazy.restart()),
    Key([_mod, "shift"], "Escape", lazy.shutdown()),
] + [
    # generate key bindings for groups
    Key([_mod] + fmods + gmods, key, func)
    for fmods, func in [
        ([       ], lazy.group[group.name].toscreen()),
        (["shift"], lazy.window.togroup(group.name)),
    ]
    for group, (key, gmods) in zip(groups, [
        (key, mods)
        for key in _groupKeys
        for mods in [[], ['control']]
    ])
]
