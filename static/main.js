const connectDiv = document.querySelector("#connectDiv")
const connectForm = document.querySelector("#connectForm")
const hostname = document.querySelector("#hostname")
const port = document.querySelector("#port")
const mainDiv = document.querySelector("#mainDiv")
const sendForm = document.querySelector("#sendForm")
const command = document.querySelector("#command")

function output(text) {
  const outputDiv = document.querySelector("#output")
  const p = document.createElement("p")
  p.tabIndex = "0"
  p.innerText = text
  outputDiv.appendChild(p)
  outputDiv.scrollTo(0, outputDiv.scrollHeight)
}

window.onload = () => {
  mainDiv.hidden = "true"
  hostname.focus()
  connectForm.onsubmit = (e) => {
    e.preventDefault()
    const h = hostname.value
    const p = port.value
    const con = new WebSocket(`ws://${window.location.hostname}:${window.location.port}/ws`)
    sendForm.onsubmit = (e) => {
      e.preventDefault()
      const data = command.value
      command.value = ""
      con.send(data)
    }
    con.onopen = () => {
      connectDiv.hidden = true
      mainDiv.hidden = false
      output("<< Connected >>")
      con.send(h)
      con.send(p)
      command.focus()
    }
    con.onclose = () => {
      output("<< Disconnected >>")
      connectDiv.hidden = false
      hostname.focus()
  }
    con.onmessage = (e) => output(e.data)
  }
}
