-- HTTP client: .http request collections, environments, chained requests and
-- imports from Postman / OpenAPI / Bruno (kulala.nvim). The collections
-- themselves live in http/ at the repository root, outside nvim/.
-- rest.nvim is not used.

local spec = require("settings").spec

return {
  spec("mistweaverco/kulala.nvim", "kulala"),
}
