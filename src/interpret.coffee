class Scope
  constructor: () ->

interpret: (ast, errors, ctx) ->
  scope = new Scope()
  
  # Register each decl in the AST
  # Run metas
  # Run program
  