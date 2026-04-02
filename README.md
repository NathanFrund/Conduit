# Conduit

Conduit is an **Asset Resolution Layer** that provides:

1. **Dynamic Resolution**: Fallback logic between FileSystem and Compiled Methods.
2. **Persistence**: The ability to "freeze" external assets into the Pharo image.
3. **Framework Agnosticism**: A Trait-based API that works with Teapot, Zinc, or Seaside.

By leveraging Smalltalk **Traits**, Conduit allows you to inject web-rendering and asset-freezing capabilities into any class, making it framework-agnostic and highly modular.

## Installation

To install Conduit in a fresh Pharo image, execute the following Metacello script. Note that *Teapot* is expected to be present in your Pharo environment.

*Mustache* will be loaded automatically as a dependency.

```smalltalk
Metacello new
    baseline: 'Conduit';
    repository: 'github://NathanFrund/Conduit:main/src';
    load.
```

## 🚀 Quick Start

Once you have composed your class with the Conduit traits, you can spin up the server in two modes:

### 1. Live Development Mode

Point the engine to your local directory. Changes to `.mustache` files on your disk will reflect instantly in the browser.

```smalltalk
app := ConduitTraitWebApp new.
app startOn: '/Users/name/Projects/my-web-assets'.
```

### 2. Frozen / Production Mode

If you have already run `freeze:`, you can start the app without a local path. It will serve templates directly from the compiled Smalltalk methods.

```smalltalk
app := ConduitTraitWebApp new.
app startOn: nil.
```

## 🏗 Trait-Based Architecture

Conduit has been refactored from a monolithic class into a modular Trait system. This allows you to "plug in" hybrid-state capabilities to any object, including Seaside components or Zinc delegates.

### The Composition

To create a Conduit-powered app, compose your class as follows:

| Side | Trait | Responsibility |
|:---|:---|:---|
| **Instance** | `TConduitRenderer` + `THtmxRenderer` | Template resolution, HTMX support, page rendering |
| **Class** | `TConduitFreezable` | `freeze:` and `unfreeze` actions |

### The Developer Contract

To satisfy the traits, your application class must implement the following:

| Requirement | Description | Implementation |
| :--- | :--- | :--- |
| **`conduit`** | A method returning the `Conduit` engine instance. | `^ conduit` |
| **`server` slot** | A slot to hold your HTTP server (e.g., Teapot). | Defined in class slots. |
| **`rootPath` slot** | A slot to store the `FileReference` for live mode. | Defined in class slots. |

---

## How It Works: The Hybrid-State Logic

The core value of Conduit is its ability to resolve templates across different storage mediums using a prioritized fallback:

1. **Disk Priority**: The engine first checks the `conduit` registry for a live file on disk.
2. **Image Fallback**: If the disk is unavailable or the file is missing, it looks for a method named `frozenTemplate<Name>` on the instance side.
3. **Layout Wrapping**: It automatically looks for a `layout` template. If found, it wraps the page content within it using the `{{{content}}}` placeholder.
4. **Partial Injection**: It scans all selectors beginning with `frozenTemplate` to automatically resolve Mustache partials (e.g., `{{> navbar}}`).

---

## Freezing for Production

You can "bake" your external HTML files and assets (CSS/JS) into the Pharo image so the app can run as a standalone binary without any external dependencies:

```smalltalk
"Bake all templates and assets into the class"
ConduitTraitWebApp freeze: '/path/to/shared'.

"Clean them out later if needed"
ConduitTraitWebApp unfreeze.
```

- **`freeze:`** Scans the directory and compiles each `.mustache` file as a method prefixed with `frozenTemplate`, and each asset (CSS/JS) as `frozenAsset*` methods.
- **`unfreeze`**: Removes all `frozenTemplate*` and `frozenAsset*` methods from the instance side.

> **Note:** The directory structure expected by `freeze:` should contain:
> ```
> shared/
> ├── templates/    (.mustache files)
> ├── css/          (.css files)
> └── js/           (.js files)
> ```

---

## Example Implementation: `ConduitTraitWebApp`

The included `ConduitTraitWebApp` serves as a reference implementation. It demonstrates how to initialize the `server` (Teapot) and map routes to the `renderPage:` method provided by the traits.

```smalltalk
"Example Route Mapping"
server GET: '/' -> [ self renderPage: 'index' ].
server GET: '/clicked' -> [ :req |
    self render: 'clicked_response' request: req 
        context: { ('time' -> Time now print24) } asDictionary ].
server GET: '/<page>' -> [ :req | 
    self renderPage: (req at: #page) ].
```

---

## Testing

Conduit includes a full test suite. To run the tests:

```smalltalk
TestRunner open.
"Select the Conduit-Tests package"
```

---

## License

Conduit is released under the MIT License.
