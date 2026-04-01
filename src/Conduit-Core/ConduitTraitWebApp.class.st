"
I am a lightweight web application server built on Teapot and HTMX.

I provide a bridge between server-side Mustache templates and modern, reactive front-end interactions without requiring custom JavaScript. My primary role is to manage the application lifecycle, route HTTP requests, and resolve template partials from either the disk or ""frozen"" methods.

## 1. Responsibilities
Routing: I define the URL structure of the application in my startOn: method.

Template Registry: I build and maintain a dictionary of MustacheTemplate objects via resolvePartials.

HTMX Integration: By using the THtmxRenderer trait, I automatically decide whether to return a full HTML page (with layout) or a partial fragment based on the HX-Request header.

## 2. Collaborators
THtmxRenderer (Trait): Provides the core logic for the ""Full vs. Fragment"" rendering switch.

Teapot: The underlying routing engine and HTTP server.

Conduit: The back-end engine that provides the data registry and file system access.

## 3. Essential Methods
startOn: - Initializes the Teapot server and sets up the routes.

resolvePartials - The central hub for template lookup. It checks the Conduit registry first, then falls back to frozenTemplate* methods.

renderFullPage:context: - Defines the ""shell"" of the application (headers, nav, footer) where the content is injected.

## 4. Example Usage
Smalltalk
""To start the application on port 8081""
app := ConduitTraitWebApp new startOn: 8081.

""To stop the application""
app stop.
"
Class {
	#name : 'ConduitTraitWebApp',
	#superclass : 'Object',
	#traits : 'TConduitRenderer + THtmxRenderer',
	#classTraits : 'TConduitRenderer classTrait + THtmxRenderer classTrait + TConduitFreezable classTrait',
	#instVars : [
		'conduit',
		'rootPath',
		'server'
	],
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'as yet unclassified' }
ConduitTraitWebApp class >> killAll [
    "Emergency cleanup: kill all running instances and background processes"
    
    "Stop all app instances"
    self allInstances do: [ :each | each stop ].
    
    "Kill any Conduit watcher processes"
    Process allInstances do: [ :p |
        (p name notNil and: [ p name includesSubstring: 'Conduit' ]) 
            ifTrue: [ 
                Transcript show: 'Terminating process: ', p name; cr.
                p terminate ] ].
    
    "Kill any Teapot servers"
    Teapot stopAll.
    
    "Force garbage collection"
    Smalltalk garbageCollect.
    
    Transcript show: 'All Conduit processes terminated.'; cr.
]

{ #category : 'accessing' }
ConduitTraitWebApp >> conduit [ 
	"Satisfies TConduitRenderer requirement"
	^ conduit
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> serveFrozenAsset: aPathString [
    "Try to find a frozen method for a given path like 'css/style.css'"
    | fileRef methodName |
    fileRef := aPathString asFileReference.
    methodName := ('frozenAsset', fileRef base capitalized, fileRef extension capitalized) asSymbol.
    
    Transcript show: 'serveFrozenAsset called with: ', aPathString; cr.
    Transcript show: '  fileRef base: ', fileRef base; cr.
    Transcript show: '  fileRef extension: ', fileRef extension; cr.
    Transcript show: '  Looking for method: ', methodName; cr.
    
    (self respondsTo: methodName) ifTrue: [ 
        Transcript show: '  ✓ Method found! Returning content.'; cr.
        ^ ZnResponse ok: (ZnEntity 
            with: (self perform: methodName) 
            type: (ZnMimeType 
                forFilenameExtension: fileRef extension 
                ifAbsent: [ ZnMimeType applicationOctetStream ])) ].
    
    Transcript show: '  ✗ Method NOT found!'; cr.
    ^ ZnResponse notFound: aPathString
]

{ #category : 'accessing' }
ConduitTraitWebApp >> server [
	^ server
]

{ #category : 'public' }
ConduitTraitWebApp >> startOn: aPath [
    self stop.

    rootPath := aPath ifNotNil: [ aPath asFileReference ].

    "Initialize the engine"
    rootPath ifNotNil: [
        conduit := Conduit pointingAt: rootPath pathString.
        conduit start ].

    "Setup Teapot"
    server := Teapot configure: { (#port -> 8081) }.

    "Static Assets - Disk (Development)"
    rootPath ifNotNil: [
        server serveStatic: '/static' from: rootPath pathString ].

    "Static Assets - Frozen Fallback (Production)"
    server GET: '/static/*' -> [ :req | 
        | fullPath assetPath |
        fullPath := req url path.
        assetPath := fullPath allButFirst: 8.  "Remove '/static/'"
        self serveFrozenAsset: assetPath ].

    "HTMX Click Handler"
    server GET: '/clicked' -> [ :req |
        self render: 'clicked_response' request: req 
            context: { ('time' -> Time now print24) } asDictionary ].

    "General Routing"
    server GET: '/' -> [ self renderPage: 'index' ].
    server GET: '/<page>' -> [ :req | self renderPage: (req at: #page) ].

    server start.
    Transcript show: 'Server started on port 8081'; cr.
]

{ #category : 'accessing' }
ConduitTraitWebApp >> stop [
    "Completely stop the server and clean up all background processes"
    
    "1. Stop the Teapot server"
    server ifNotNil: [ 
        server stop.
        server := nil ].
    
    "2. Stop the Conduit engine and kill its watcher process"
    conduit ifNotNil: [ 
        conduit stop.      "This should terminate the watcherProcess"
        conduit := nil ].
    
    "3. Safety: Kill any lingering Conduit watcher processes by name"
    Process allInstances do: [ :p |
        (p name notNil and: [ p name includesSubstring: 'ConduitWatchr' ]) 
            ifTrue: [ p terminate ] ].
    
    "4. Clear Teapot instances from the port"
    Teapot stopAll.
    
    Transcript show: 'WebApp fully stopped and cleaned up.'; cr.
]
