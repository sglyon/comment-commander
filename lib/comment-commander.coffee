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
    return atom.config.getAll('editor.commentStart', {scope})[0].value

  # Create the header that will be used to replace
  #
  # editor - An instance of an atom text editor
  #
  # A String containing the comment start mark
  createHeader: (commentStarter, headContent, numLeadSpace) ->
      # extract the filler from the package settings
      filler = atom.config.get('comment-commander.fillerMark')

      # create lines
      filled = Array(headContent.length+1).join(filler)
      topBtmLines = "#{commentStarter}#{filled} #{commentStarter}\n"
      midLine = "#{commentStarter}#{headContent} #{commentStarter}\n"

      fillSpaces = Array(numLeadSpace).join(' ')
      out = "#{topBtmLines}#{fillSpaces}#{midLine}#{fillSpaces}#{topBtmLines}"

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
      commentStarter = @getCommentStarter editor
      fullContent = @createHeader(commentStarter, headContent, position[0].column+1)
      # console.log fullContent

      # now do replacement
      editor.setTextInBufferRange(position, fullContent)
