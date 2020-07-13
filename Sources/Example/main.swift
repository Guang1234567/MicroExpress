import Swift_Express

let app = Express()

// Logging
app.use { req, res, next in
    print("\(req.header.method):", req.header.uri)
    next() // continue processing
}

app.use(querystring, cors(allowOrigin: "*")) // parse query params

app.get("/hello") { _, res, _ in
    res.send("Hello")
}

app.get("/moo") { _, res, _ in
    res.send("Moo!")
}

app.get("/todomvc") { _, res, _ in
    // send JSON to the browser
    res.json(todos)
}

app.get { req, res, _ in
    let text = req.param("text")
               ?? "Schwifty"
    res.send("Hello, \(text) world!")
}

app.listen(1337)