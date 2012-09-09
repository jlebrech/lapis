
module "lapis.router", package.seeall

export Router

-- todo: splats in routes (*)
-- Cmt conditions on routes
-- pattern classes
--    :something[num] *[slug]

import p from require "moon"
import insert from table

require "lpeg"

import R, S, V, P from lpeg
import C, Cs, Ct, Cmt, Cg, Cb, Cc from lpeg

reduce = (items, fn) ->
  return items[1] if #items == 1
  left = fn items[1], items[2]
  for i = 3, #items
    left = fn left, items[i]
  left

class Router
  alpha = R("az", "AZ", "__")
  alpha_num = alpha + R("09")
  slug = (alpha_num + S("-")) ^ 1

  make_var = (str) ->
    name = str\sub 2
    Cg slug, name

  make_lit = (str) -> P(str)

  symbol = P":" * alpha * alpha_num^0
  chunk = (1 - symbol)^1 / make_lit + symbol / make_var

  @route_grammar = Ct(chunk^1) / (parts) ->
    patt = reduce parts, (a,b) -> a * b
    Ct patt

  new: =>
    @routes = {}
    @named_routes = {}

  add_route: (route, responder) =>
    @p = nil
    name = nil
    if type(route) == "table"
      name = next route
      route = route[name]
      @named_routes[name] = route

    insert @routes, { route, responder, name }

  build: =>
    @p = reduce [@build_route unpack r for r in *@routes], (a, b) -> a + b
  
  build_route: (path, responder, name) =>
    @@route_grammar\match(path) * -1 / (params) ->
      params, responder, path, name

  url_for: (name, params) =>
    replace = (s) -> params[s\sub 2] or ""
    patt = Cs (symbol / replace + 1)^0
    route = assert @named_routes[name]
    patt\match route

  resolve: (route, ...) =>
    @build! unless @p
    params, responder, path, name = @p\match route
    error "failed to route: " .. route unless params
    responder params, path, name, ... if responder
