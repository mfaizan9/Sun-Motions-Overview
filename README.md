# Sun Motions Overview — HTML5

**This simulation must be served over HTTP. It will not run from a double-clicked
`index.html` (a `file://` path).**

## Why

The shared KL-UNL masthead (`foundation/kl-unl-masthead.js`) loads the
simulation's title and its Help and About text by calling
`fetch('foundation/contents.json')`. Browsers block `fetch()` of local files
under the `file://` protocol for security reasons (the same-origin policy), so
opening `index.html` directly gives you an empty or broken masthead — no title,
no Reset, no Help, no About. Served over HTTP the fetch succeeds and the
simulation loads normally.

## How to run it locally

Run one of these **from inside the `html5/` folder**:

```
# Python 3
python3 -m http.server 8123

# Node
npx serve
# or
npx http-server
```

Then open <http://localhost:8123/>.

Because you are serving *from inside* `html5/`, the simulation sits at the
server root — the URL is `http://localhost:8123/`, **not**
`http://localhost:8123/html5/index.html`.

In VS Code you can instead use the **Live Server** extension: right-click
`index.html` and choose "Open with Live Server".

## Production

Once deployed to the cloud host (served over HTTP/HTTPS) it just works. The
`file://` limitation only affects opening the file directly from disk.

## What is in this folder

| Path | Contents |
| --- | --- |
| `index.html` | KL-UNL scaffold: `.app-shell`, `<kl-unl-masthead>`, and the panels |
| `foundation/` | Shared KL-UNL files, copied in unchanged (only this sim's `contents.json` entry was edited) |
| `styles/styles.css` | Sim-specific styles only |
| `simulation.js` | All simulation logic |
| `assets/shapes/` | Vector art reused as-is from the Flash export |
| `assets/mathjax/` | MathJax, vendored locally (no CDN) |
| `CONVERSION_NOTES.md` | Behaviour model, ActionScript → HTML5 mapping, deviations |
| `ACCESSIBILITY.md` | WCAG affordances, keyboard map, screen-reader notes |

Everything is local: the only network requests are to files in this folder.
