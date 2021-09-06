let capability = ("handleWrappingAstNode", `Bool true)

let meth = "ocamllsp/wrappingAstNode"

let on_request ~params:_ _state =
  failwith "Req_wrapping_ast_node.on_request"
