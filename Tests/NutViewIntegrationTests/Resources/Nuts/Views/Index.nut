<!-- Posts.html -->

\Title("Index")
\Head("<link rel=\"stylesheet\" type=\"text/css\" href=\"mystyle.css\">")
\if let name = username, name == "Tom" {
    <h1>Hello Tom</h1>
\} else if let name = username {
    <h1>Hello \(name)</h1>
\} else {
    I dont know you
\}
