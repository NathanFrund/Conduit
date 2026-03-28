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
	#classTraits : 'TConduitRenderer classTrait + THtmxRenderer classTrait',
	#instVars : [
		'conduit',
		'rootPath',
		'server'
	],
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'accessing' }
ConduitTraitWebApp >> conduit [ 
	"Satisfies TConduitRenderer requirement"
	^ conduit
]

{ #category : 'public' }
ConduitTraitWebApp >> startOn: aPath [

	self stop. "Clean up any existing instance before starting a new one"

	rootPath := aPath ifNotNil: [ aPath asFileReference ].

	"Initialize the engine"
	rootPath ifNotNil: [
			conduit := Conduit pointingAt: rootPath pathString.
			conduit start ].

	"Setup Teapot"
	server := Teapot configure: { (#port -> 8081) }. "Using 8081 to avoid conflict"

	server GET: '/' -> [ self renderPage: 'index' ].

	server GET: '/clicked' -> [ :req |
			Transcript
				show: 'HTMX Request received!';
				cr.
			self
				render: 'clicked_response'
				request: req
				context: { ('time' -> Time now print24) } asDictionary ].

	server GET: '/<page>' -> [ :req | self renderPage: (req at: #page) ].

	server start.
	Transcript
		show: 'New WebApp started on 8081';
		cr
]

{ #category : 'accessing' }
ConduitTraitWebApp >> stop [
    "1. Stop the Teapot server"
    server ifNotNil: [ 
        server stop. 
        server := nil ].

    "2. Stop the Conduit engine (if it was started)"
    conduit ifNotNil: [ 
        conduit stop. 
        conduit := nil ].

    "3. Nuclear option: ensure all Teapot instances are cleared"
    Teapot stopAll.
    
    Transcript show: 'WebApp and Conduit engine stopped.'; cr.
]
