# Comment Commander

Take command of comment blocks


Takes text like this:

```python
This section does something great
```

And replaces it with

```python
# --------------------------------- #
# This section does something great #
# --------------------------------- #
```

Features:

- The filler mark is configurable in the package settings (in the above example it is set to `-`).
- Works for arbitrary languages by extracting the comment start marker atom uses for the command `editor:toggle-line-comments`
