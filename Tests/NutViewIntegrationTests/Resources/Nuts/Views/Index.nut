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
<h1>\Date(today)</h1>
<h2>\Date(today, format: someFormat)</h2>
<h3>\Date(today, format: "dd mm hh")</h3>
