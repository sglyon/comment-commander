{CompositeDisposable} = require 'atom'

module.exports =
  subscriptions: null

  config:
    fillerMark:
      type: 'string'
      default: '-'
      title: 'Filler'
      description: """\
      Filler to be placed between comment start/end markers above/below header\
      """

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'comment-commander:format-comment': => @formatComment()

  deactivate: ->
    @subscriptions.dispose()

  # Returns the position of the first and last characters in the cursor's
  # current line
  #
  # editor - An instance of an atom text editor
  #
  # Returns a pair of Points, specifying the first and last characters of the
  # non whitespace content on the current line
  headPos: (editor) ->
    startPos = editor.getCursorBufferPosition()

    # now move to first character of the line, then extract buffer position
    editor.moveToFirstCharacterOfLine()
    headBegin = editor.getCursorBufferPosition()

    # do the same to extract the last character of line
    editor.moveToEndOfLine()
    headEnd = editor.getCursorBufferPosition()

    # return the cursor where we found it
    editor.setCursorBufferPosition(startPos)

    return [headBegin, headEnd]

  # Get character(s) that starts a comment for the given grammar
  #
  # editor - An instance of an atom text editor
  #
  # A String containing the comment start mark
  getCommentStarter: (editor) ->
    # extract the comment begin marker
    pos = editor.getCursorBufferPosition()
    scope = editor.scopeDescriptorForBufferPosition(pos)
    out = null

    # get the commentStart and blockCommentStart strings
    commentStart = atom.config.getAll('editor.commentStart', {scope})?[0]?.value.trim()
    blockCommentStart = atom.config.getAll('editor.commentStart', {scope})?[1]?.value.trim()

    # if the regular commentStart string makes sense for the end commentStart, use it
    # otherwise use the blockComment style of commenting (good for html, xml etc)
    if (/^(.)\1+$/.test commentStart) or (commentStart?.length == 1)
      out = commentStart
    else
      out = blockCommentStart or commentStart or null

    return out + ' ' if out
    return out

  # Get character(s) that ends a comment for the given grammar
  #
  # editor - An instance of an atom text editor
  #
  # A String containing the comment end mark
  getCommentEnder: (editor) ->
    # extract the comment begin marker
    pos = editor.getCursorBufferPosition()
    scope = editor.scopeDescriptorForBufferPosition(pos)

    # if the regular commentStart string makes sense for the end commentStart, use it
    # otherwise use the blockComment style of commenting (good for html, xml etc)
    commentStart = atom.config.getAll('editor.commentStart', {scope})?[0]?.value.trim()
    if (/^(.)\1+$/.test commentStart) or (commentStart?.length == 1)
      out = commentStart
    else
      out = atom.config.getAll('editor.commentEnd', {scope})?[0]?.value.trim() or null

    return ' ' + out if out
    return out

  # Create the header that will be used to replace
  #
  # editor - An instance of an atom text editor
  #
  # A String containing the comment start mark
  createHeader: (commentStarter, commentEnder,  headContent, numLeadSpace) ->
      topBtmLines = ''
      console.info 'commentStarter: ' +  commentStarter + ' | '+ 'commentEnder: ' + commentEnder
      # extract the filler from the package settings
      filler = atom.config.get('comment-commander.fillerMark')

      # create vars to hold the filler and final filled output
      # (helpful if multiple fill characters are specified)
      longFiller = ''
      filled = ''

      # populate the longFiller var (will be longer than the headContent
      # if there are more than one character specified in the fillerMark
      # config option)
      for i in Array headContent.length
        longFiller += filler

      # iterate through the longFiller string for the length of the actual
      # headContent and build the "filled" string
      i = 0
      while i < headContent.length
        filled += longFiller.charAt i
        i++

      # if we are in a grammar that supports comments, build the comment block
      if commentStarter?.length and commentEnder?.length
        topBtmLines = "#{commentStarter}#{filled}#{commentEnder}\n"
        midLine = "#{commentStarter}#{headContent}#{commentEnder}\n"

        fillSpaces = Array(numLeadSpace).join(' ')
        out = "#{topBtmLines}#{fillSpaces}#{midLine}#{fillSpaces}#{topBtmLines}"
      else
        # deal with grammars that do not have comments, or files with unknown grammar
        out = "#{headContent}"

  # Transform the contents of the current cursor line by surrounding it with
  # the comment begin marker, then appending copies of the adjusted line with
  # the original contents set to `comment-commander.fillerMark` above and below
  formatComment: ->
    if editor = atom.workspace.getActiveTextEditor()
      # I don't want to deal with this right now
      if editor.hasMultipleCursors()
        return

      # extract the body of the comment
      position = @headPos editor
      headContent = editor.getTextInBufferRange position

      # build up the actual comment we want
      commentStarter = @getCommentStarter editor or null
      commentEnder = @getCommentEnder editor or null
      fullContent = @createHeader(commentStarter, commentEnder, headContent, position[0].column+1)

      # now do replacement
      editor.setTextInBufferRange(position, fullContent)
