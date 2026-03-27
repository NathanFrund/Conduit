# Conduit

Conduit is a "Hybrid-State" web application engine for Pharo. It allows developers to seamlessly transition between a **Live** development state (reading Mustache templates from the local filesystem) and a **Frozen** production state (reading templates baked directly into Smalltalk methods).

## Installation

To install Conduit in a fresh Pharo image, execute the following Metacello script:

```smalltalk
Metacello new
    baseline: 'Conduit';
    repository: 'github://NathanFrund/Conduit:main/src';
    load.
```

### Loading with Tests

```smalltalk
Metacello new
    baseline: 'Conduit';
    repository: 'github://NathanFrund/Conduit:main/src';
    load: 'Tests'.
```

## How It Works: The Hybrid-State Logic

The core value of Conduit is its ability to resolve templates across different storage mediums. The `ConduitWebApp` uses a fallback resolver:

1. **Disk Priority**: If a `rootPath` is set, the app uses the `Conduit` engine to watch and serve live files from your Mac/PC.
2.  **Image Fallback**: If no disk path is found, the app "thaws" templates from internal methods prefixed with `frozenTemplate`.

This allows you to build your app with the comfort of an external IDE/editor and deploy it as a single, zero-dependency `.image` binary.

## Quick Start

### 1. Development Mode (Live)

Start the application by pointing it to your local template directory. Any changes to your `.mustache` files on disk are immediately available.

```smalltalk
"Starts the server on http://localhost:8080"
app := ConduitWebApp startOn: '/Users/Nathan/Development/Project/shared'.
```

### 2. Production Mode (Frozen)

When you are ready to distribute your app, "freeze" the external assets into the image. This compiles the file contents into Smalltalk methods.

```smalltalk
"Bake the folder contents into the ConduitWebApp class"
ConduitWebApp freeze: '/Users/Nathan/Development/Project/shared'.

"You can now move the image to any machine and start it without the folder"
app := ConduitWebApp new start.
```

### 3. Management

You can toggle the state of your image or stop the server using the following commands:

```smalltalk
"Remove all baked-in templates from the image"
ConduitWebApp unfreeze.

"Stop the Teapot server and cleanup"
app stop.
```

## Features

* **HTMX Ready**: Built-in route for `/clicked` to demonstrate seamless HTMX fragment swapping.
* **Layout Support**: Automatically wraps pages in a `layout.mustache` if one is present in your templates.
* **Auto-Discovery**: A dynamic catch-all route (`/<page>`) that automatically renders templates based on the URL path.

## Project Structure

* **Conduit-Core**: Contains the `Conduit` engine and the `ConduitWebApp` reference implementation.
* **ConduitCore-Tests**: Integration tests for the resolver and freezing logic.