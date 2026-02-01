///|
#cfg(target="native")
let backend_key : String = "native"

///|
#cfg(target="wasm")
let backend_key : String = "wasm"

///|
#cfg(target="js")
let backend_key : String = "js"

///|
#cfg(target="wasm-gc")
let backend_key : String = "wasm-gc"

///|
#cfg(all(not(target="native"), not(target="wasm"), not(target="js"), not(target="wasm-gc")))
let backend_key : String = "unknown"

///|
fn pack(json : Json, test_type : String, data : Json) -> Unit {
  match json {
    Object(m) =>
      match m.get(backend_key) {
        Some(Array(val)) => {
          let kvp = {}
          kvp[test_type] = data
          val.push(Json::object(kvp))
        }
        _ => {
          let kvp = {}
          kvp[test_type] = data
          m[backend_key] = Json::array([Json::object(kvp)])
        }
      }
    _ => panic()
  }
}
