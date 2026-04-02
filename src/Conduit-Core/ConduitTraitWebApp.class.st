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
		'server',
		'port'
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

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> announceStarted [
    "Notify that the server is running"
    
    Transcript 
        show: 'Conduit server started on port ', port asString;
        show: ' (', (rootPath ifNil: [ 'frozen' ] ifNotNil: [ 'disk' ]), ' mode)';
        cr.
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> cleanupProcesses [
    "Terminate any leftover background processes"
    
    Process allInstances do: [ :p |
        (p name notNil and: [ p name includesSubstring: 'ConduitWatchr' ]) 
            ifTrue: [ p terminate ] ].
    
    Teapot stopAll.
]

{ #category : 'accessing' }
ConduitTraitWebApp >> conduit [ 
	"Satisfies TConduitRenderer requirement"
	^ conduit
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> configureRoutes [
    server GET: '/' -> [ self renderPage: 'index' ].
    server GET: '/clicked' -> [ :req |
        self render: 'clicked_response' request: req 
            context: { ('time' -> Time now print24) } asDictionary ].
    server GET: '/<page>' -> [ :req | 
        self renderPage: (req at: #page) ].
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> configureServerOnPort: aPortNumber [
    "Configure the Teapot server with all routes"
    
    server := Teapot configure: { (#port -> aPortNumber) }.
    
    self configureStaticAssets.
    self configureRoutes.
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> configureStaticAssets [
    "Set up static asset serving for both disk and frozen modes"
    
    "Disk mode: serve directly from filesystem"
    rootPath ifNotNil: [
        server serveStatic: '/static' from: rootPath pathString.
        Transcript show: 'Static assets from disk: ', rootPath pathString; cr ].
    
    "Frozen mode only: serve from methods"
    rootPath ifNil: [
        server GET: '/static/*' -> [ :req | 
            | fullPath assetPath |
            fullPath := req url path.
            assetPath := fullPath copyFrom: 9 to: fullPath size.  "Remove '/static/'"
            Transcript show: 'Frozen static request: ', assetPath; cr.
            self serveFrozenAsset: assetPath ] ].
]

{ #category : 'initialization' }
ConduitTraitWebApp >> initialize [
    "Set up default values for a new instance"
    
    super initialize.
    port := 8081.
    rootPath := nil.
    conduit := nil.
    server := nil.
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> port: aPortNumber [
    "Set the port for the next start"
    port := aPortNumber.
    ^ self  "Return self for fluency"
]

{ #category : 'accessing' }
ConduitTraitWebApp >> rootPath: aPath [
    "Set the disk path for the next start"
    rootPath := aPath asFileReference.
    ^ self
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

{ #category : 'initialization' }
ConduitTraitWebApp >> setModeFromPath: aPath [
    "Configure disk mode or frozen mode based on path"
    
    aPath ifNil: [ 
        "Frozen mode — no disk access"
        rootPath := nil.
        conduit := nil.
        ^ self ].
    
    "Disk mode — set up hot reload"
    rootPath := aPath asFileReference.
    self setupDiskWatcher.
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> setupDiskWatcher [
    | templatesPath |
    templatesPath := rootPath / 'templates'.
    templatesPath exists ifTrue: [
        conduit := Conduit pointingAt: templatesPath pathString.
        conduit start ].
]

{ #category : 'public' }
ConduitTraitWebApp >> startOn: aPath [
    "Start the server. If aPath is provided, use disk mode with hot reload.
     If aPath is nil, use frozen mode (requires frozen methods)."
    
    self startOn: aPath port: (port ifNil: [ 8081 ])
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> startOn: aPath port: aPortNumber [
    "Start the server on the specified port with optional disk path"
    
    self stop.
    
    "Store the port"
    port := aPortNumber.
    
    "Set up the mode and configuration"
    self setModeFromPath: aPath.
    self configureServerOnPort: aPortNumber.
    
    "Start the server"
    server start.
    
    self announceStarted.
]

{ #category : 'accessing' }
ConduitTraitWebApp >> stop [
    "Gracefully stop the server and clean up resources"
    
    self stopServer.
    self stopDiskWatcher.
    self cleanupProcesses.
    
    Transcript show: 'Conduit server stopped.'; cr.
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> stopDiskWatcher [
    conduit ifNotNil: [ 
        conduit stop.
        conduit := nil ].
]

{ #category : 'public' }
ConduitTraitWebApp >> stopServer [
    server ifNotNil: [ 
        server stop.
        server := nil ].
]

{ #category : 'as yet unclassified' }
ConduitTraitWebApp >> withHotReload [
    "Ensure disk mode is active (kept for backward compatibility)"
    ^ self
]
