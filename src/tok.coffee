Lexer = require('lex')

# Token looks like
{ "kind": "int", "val": "3", "start": 456, "len": 1 }

_token = (kind, st, lexeme) ->
  info = {
    "kind": kind,
    "val": lexeme,
    "line": st.line_num,
    "line_offset": st.line_offset,
    "token_offset": st.token_offset }
  st.token_offset += lexeme.length
  return info

tok = (src, errors, ctx) ->
  lexer = new Lexer();
  state = {}
  state.line_num = 1
  state.line_offset = 0
  state.block_comment = 0
  
  # TODO: multiline strings
  # TODO: ( ) [ ] use same line, but { } do not
  
  # identifier (includes keywords)
  lexer.addRule(/[a-z_][a-z0-9_]*/i, (lexeme) ->
    if state.block_comment == 0
      return _token("ident", state, lexeme)
  )
  
  # line comment
  lexer.addRule(/\/\/[^\n]*/i, (lexeme) ->

    _token("comment", state, lexeme) # ignore
    return undefined
  )
  
  # decimal
  lexer.addRule(/\d+(?:\.\d+)/i, (lexeme) ->
    if state.block_comment == 0
      return _token("decimal", state, lexeme)
  )
  
  # integer
  lexer.addRule(/\d+/i, (lexeme) ->
    if state.block_comment == 0
      return _token("integer", state, lexeme)
  )
  
  # string
  lexer.addRule(/\"(?:\\\\|\\"|[\s\S])+\"/i, (lexeme) ->
    if state.block_comment == 0
      return _token("string", state, lexeme)
  )
  lexer.addRule(/\'(?:\\\\|\\'|[\s\S])+\'/i, (lexeme) ->
    if state.block_comment == 0
      return _token("string", state, lexeme)
  )
  
  # TODO: god damn multiline strings
  
  
  # block comment start
  lexer.addRule(/\/\*/i, (lexeme) ->
    # block comments nest because no #if 0
    state.block_comment += 1
    _token("comment", state, lexeme) # ignore
    return undefined
  )
  # block comment end
  lexer.addRule(/\*\//i, (lexeme) ->
    if state.block_comment > 0
      state.block_comment -= 1
    _token("comment", state, lexeme) # ignore
    return undefined
  )
  
  # fused symbol
  lexer.addRule(/\|\||&&|==|<=|>=|<<|>>|->|=>/i, (lexeme) ->
    if state.block_comment == 0
      return _token("symbol", state, lexeme)
  )
  
  # single symbol
  lexer.addRule(/[!@#$%\^&*()\-+={}[\]:;|\\<,>.?\/~`]/i, (lexeme) ->
    if state.block_comment == 0
      return _token("symbol", state, lexeme)
  )
  
  # whitespace
  lexer.addRule(/\s+/i, (lexeme) ->
    _token("space", state, lexeme) # ignore
    return undefined
  )
  
  lines = src.match(/[^\n]+\n?/g)
  output_lines = []
  for line in lines
    console.log(line)
    n = line.length
    state.token_offset = 0
    
    lexer.setInput(line)
    
    results = []
    while true
      item = lexer.lex()
      if not item?
        break
      results.push(item)
    console.log(results)
    
    state.line_num += 1
    state.offset += n
    output_lines.push({
      "toks": results,
    })
  return output_lines

tok("abc/*\nboo */bar'foo'===123.34 12\n")
