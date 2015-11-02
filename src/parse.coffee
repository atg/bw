class TokBuffer
  constructor: (line) ->
    @toks = line.toks.slice()
    
    # TODO: just use an index here instead of reversing
    @toks.reverse() # reverse in place
  
  peek: () ->
    if @toks.length > 0
      return @toks[0]
    else
      return null
  
  pop: () ->
    if @toks.length > 0
      return @toks.pop()
    else
      return null
  
  isEmpty: () ->
    return @toks.length == 0


# TODO: eval insertions.
# At certain times, if there's an unexpected token, eval the loaded parser extensions
# each parser extension binding point gets a name, e.g.
#   [extpoint] decls.0

parse = (lines, errors, ctx) ->
  state = { "mode": ["decls"] }
  
  _parseBody = (line, toks, isMeta, callback) ->
    # { stmt1 EOL stmt2 EOL stmt3 }
    state.jobs.push({
      "mode": "body",
      "ctx": [],
      "callback": ((job) ->
        info = { "kind": "body", "stmts": job.ctx }
        callback(info))
    })
    
  _parseDeclFn = (line, toks, isMeta) ->
    # name <typeparams> ( params ) { body }
  
  _parseDeclLet = (line, toks, isMeta) ->
    # name = expr
    # name { body }
    
  
  _parseDeclUse = (line, toks, isMeta) ->
    # moduleName
    # moduleName: symbol1, symbol2, symbol3
    moduleName = toks.pop()
    useDecl = {
      "kind": "use",
      "isMeta": isMeta,
    }
    
    if not moduleName?
      errors.error(toks.prev(), "use ___ what?")
      return false
    
    if moduleName.kind != "ident"
      errors.error(moduleName, "Unexpected %s", [moduleName])
      return false
    
    # expect : or EOL now
    colon = toks.pop()
    if not colon?
      return useDecl
    
    if colon.kind != "symbol" or colon.val != ":"
      errors.warning(colon, "Ignoring unexpected %s", [colon])
      return useDecl
    
    # comma separated list of idents
    # TODO
    
    
  
  _parseDeclMeta = (line, toks) ->
    head2 = toks.pop()
    if head2?
      if head2.val == "fn"
        return _parseDeclFn(line, toks, true)
      else if head2.val == "let"
        return _parseDeclLet(line, toks, true)
      else if head2.val == "use"
        return _parseDeclUse(line, toks, true)
      else
        # [extpoint] decl.meta.0
        errors.error(head, "Unexpected word %s", [head2])
        return false
    else
      errors.error(toks.prev(), "meta ___ what?")
      return false
  
  _parseDecls = (line, toks) ->
    head = toks.pop()
    if head.kind == "ident"
      if head.val == "fn"
        # function decl
        return _parseDeclFn(line, toks, false)
      else if head.val == "let"
        # let decl
        return _parseDeclLet(line, toks, false)
      else if head.val == "meta"
        # meta decl
        return _parseDeclMeta(line, toks)
      else if head.val == "use"
        # use decl
        return _parseDeclUse(line, toks, false)
      else
        # [extpoint] decl.0
        errors.error(head, "Unexpected word %s", [head])
        return false
    else
      # [extpoint] decl.0
      errors.error(head, "Unexpected %s", [head])
      return false
  
  _parseFn = (line, toks) ->
    undefined
  
  _parseStmts = (line, toks) ->
    head = toks.pop()
    if head.kind == "ident"
      switch head.val
        when "if"
          _parseStmtIf(line, toks)
        when "else"
          _parseStmtElse(line, toks)
        when "for"
          _parseStmtFor(line, toks)
        when "let"
          _parseStmtVar(line, toks, 'let')
        when "var"
          _parseStmtVar(line, toks, 'var')
        when "match"
          _parseStmtMatch(line, toks)
        when "rt", "return"
          _parseStmtReturn(line, toks)
        when "break"
          _parseStmtBreak(line, toks)
        when "continue"
          _parseStmtContinue(line, toks)
        when "yield"
          _parseStmtYield(line, toks)
        when "async"
          _parseStmtAsync(line, toks)
        else
          # [extpoint] stmt.0
          assert False
  
  for line in lines
    toks = new TokBuffer(line.toks)
    
    # ignore empty lines
    if toks.isEmpty()
      continue
    
    job = state.jobs[state.jobs.length - 1]
    mode = job.mode
    if mode == "decls"
      _parseDecls(line, toks)
    else if mode == "body"
      _parseBody(line, toks)
    else
      # [extpoint] job.0
      assert False

    