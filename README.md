# Conduit

Conduit is an **Asset Resolution Layer** that provides:

1. **Dynamic Resolution**: Fallback logic between FileSystem and Compiled Methods.
2. **Persistence**: The ability to “freeze” external assets into the Pharo image.
3. **Framework Agnosticism**: A Trait‑based API that works with Zinc, Teapot, or any HTTP server.

By leveraging Smalltalk **Traits**, Conduit allows you to inject web‑rendering and asset‑freezing capabilities into any class, making it framework‑agnostic and highly modular.

## Installation

Mustache is loaded automatically as a dependency. No Teapot or other server is required — Conduit works with plain Zinc out of the box.

```smalltalk
Metacello new
    baseline: 'Conduit';
    repository: 'github://NathanFrund/Conduit:main/src';
    load.
```

To load the test suite as well:

```smalltalk
Metacello new
    baseline: 'Conduit';
    repository: 'github://NathanFrund/Conduit:main/src';
    load: 'Tests'.
```

## Quick Start / Demo

The repo includes `ConduitWebAppDemo`, a compact example that uses **only Zinc** and the Conduit traits.

```smalltalk
"Start the demo in disk mode – templates are hot‑reloaded"
demo := ConduitWebAppDemo new.
demo rootPath: '/path/to/my-templates'.
demo start.
```

Open `http://localhost:8080/index` in your browser.  
Changes to `.mustache` files are reflected immediately — no restart needed.

**Freeze the templates into the image** (after stopping the server)

```smalltalk
ConduitWebAppDemo freezeTemplates: '/path/to/my-templates'.
```

**Restart in frozen mode (no disk)**

```smalltalk
demo2 := ConduitWebAppDemo new.
demo2 start.
```

The same pages are served from compiled Smalltalk methods.  
Later, `ConduitWebAppDemo unfreeze` removes all frozen methods.

---

## Architecture

Conduit is a set of **Traits** that you compose into your own application class.

| Side | Trait | Responsibility |
| :--- | :--- | :--- |
| **Instance** | `TConduitRenderer` + `THtmxRenderer` | Template resolution, HTMX detection, page rendering |
| **Class** | `TConduitFreezable` | Freezing and unfreezing templates |

Your class must provide a `conduit` accessor (returning a `Conduit` instance or `nil` in frozen mode), and implement the server‑lifecycle methods (`start`/`stop`). The traits supply `templateNamed:`, `resolvePartials`, `freezeTemplates:`, and `unfreeze`.

---

## Rendering API (Explicit by Default)

Conduit now provides a clean, explicit API for rendering. The implicit `render:request:context:` method has been removed. Use the following methods directly in your route handlers:

- **`renderPage: aPageName context: aDictionary`** – renders a full HTML page with automatic layout selection (see below).
- **`renderFragment: aPageName context: aDictionary`** – renders only the template fragment, with no layout.
- **`isHtmxRequest: aRequest`** – utility to check for the `HX-Request` header (returns a Boolean).

A convenience method is available for routes that want automatic HTMX‑aware switching:

- **`renderAuto: aTemplateName request: aRequest context: aDictionary`** – delegates to `renderPage:` or `renderFragment:` based on the `HX-Request` header. If the request is `nil`, it defaults to a full page.

The explicit methods are recommended for most use cases; `renderAuto:` is a thin utility for rapid prototyping.

---

## Automatic Page‑Specific Layouts

When rendering a full page, Conduit automatically looks for a page‑specific layout template.

**Convention:** For a page named `home`, Conduit first looks for a template called `home_layout`. If that exists, it’s used as the layout; otherwise it falls back to the global `layout` template.

This works in both disk and frozen modes, and respects the same escaping rules as all other templates. Just create `dashboard_layout.mustache` and it will be picked up automatically when you call `renderPage: 'dashboard' context: ...`.

---

## Template Resolution (Path‑Based)

Conduit maps the directory structure under the root folder directly to template names.  
A file at `partials/register_form.mustache` becomes the template key `'partials/register_form'`.

Underscores in filenames (`_`) are preserved through the freeze/thaw cycle using a reversible escaping convention (double underscore `__` in method selectors).  
You never need to worry about it — the framework handles it transparently.

---

## Freezing for Production

You can “bake” your templates into the image so the app runs without any external files.

```smalltalk
"Freeze templates only (defaults to .mustache and .html files)"
ConduitWebAppDemo freezeTemplates: '/path/to/templates'.

"Optional: also freeze CSS/JS assets using dedicated helpers"
ConduitWebAppDemo freezeCSS: '/path/to/assets'.
ConduitWebAppDemo freezeJS: '/path/to/assets'.
```

- **`freezeTemplates:`** walks the entire directory tree and compiles every `.mustache`/`.html` file as an instance‑side method prefixed with `frozenTemplate`.  
  The list of frozen extensions is controlled by the class‑side method `freezableTemplateExtensions` (default: `#('mustache' 'html')`).

- **`freezeCSS:` / `freezeJS:`** are separate, optional helpers for static assets. They do **not** interfere with template resolution.

- **`unfreeze`** removes all `frozenTemplate*` methods. Frozen assets are removed separately.

---

## Example Implementation: `ConduitWebAppDemo`

`ConduitWebAppDemo` is a pure‑Zinc reference that implements the full Conduit workflow.

```smalltalk
"Class definition – composes the traits"
Object << #ConduitWebAppDemo
    traits: { TConduitRenderer. TConduitFreezable }
    slots: { #server . #conduit . #rootPath };
    tag: 'Base';
    package: 'Conduit-Core'
```

Routes are handled in `handleRequest:`; `renderPage:` uses the traits to fetch templates, resolve partials, and wrap content in the optional `layout` template.

---

## Testing

Conduit includes a full test suite covering the disk registry, frozen‑method resolution, HTMX detection, and the escaping round‑trip.

```smalltalk
TestRunner open.
"Select the Conduit‑Tests package"
```

---

## License

Conduit is released under the MIT License.
