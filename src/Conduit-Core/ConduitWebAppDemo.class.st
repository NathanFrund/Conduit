"
I am a demonstration of a ""Hybrid-State"" web application engine. 

My primary purpose is to show how a Pharo application can seamlessly transition between a ""Live"" development state (reading from the Mac filesystem) and a ""Frozen"" production state (reading from baked-in methods).

Conceptual Architecture:
1. The Resolver: I use a fallback logic in #templateNamed:. If a local directory is provided, I prioritize disk files. If not, I ""thaw"" templates from internal methods.
2. The Freezer: I provide a mechanism to compile external Mustache/HTML files into Smalltalk methods prefixed with #frozenTemplate. This allows the .image to be distributed as a single, zero-dependency binary.

Key Implementation Points:
- #rootPath: When set, the app operates in ""Live Mode."" When nil, it operates in ""Frozen Mode.""
- #frozenTemplate*: These are generated methods that act as an internal virtual filesystem.

Public API for the Demo:
- ConduitWebAppDemo freeze: aPath : Use this to ""freeze"" your HTML folder into the image.
- ConduitWebAppDemo unfreeze : Use this to ""wipe"" the frozen assets and return to a clean engine state.
- #start / #stop : Controls the Teapot/Zinc server.

Example:
    ""1. Development Mode (Live files)""
    (ConduitWebAppDemo new rootPath: '/Users/name/dev/shared') start.

    ""2. Production Mode (No files needed)""
    ConduitWebAppDemo new start.
"
Class {
	#name : 'ConduitWebAppDemo',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'conduit',
		'rootPath'
	],
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'actions' }
ConduitWebAppDemo class >> freeze: aPath [
	| folder |
	folder := aPath asFileReference.

	(folder children select: [ :each | each isFile ]) do: [ :file | 
		| content |
		content := file contents.

		"Target the instance side explicitly so 'self perform:' works later"
		self instanceSide compile: (String streamContents: [ :s |
			s nextPutAll: 'frozenTemplate'; nextPutAll: file base capitalized; cr.
			s nextPutAll: '    ^ '; nextPutAll: content asString printString ])
		classified: 'content-templates' ].

	Transcript show: 'Freeze complete: Assets baked into Instance Side.'; cr.
]

{ #category : 'public' }
ConduitWebAppDemo class >> startOn: aPath [

	| instance |
	instance := self new.
	aPath ifNotNil: [
			instance rootPath: aPath asFileReference.
			instance start ].
	^ instance
]

{ #category : 'actions' }
ConduitWebAppDemo class >> unfreeze [
    | count |
    count := 0.
    "Only target our new official prefix"
    (self instanceSide selectors select: [ :s | s beginsWith: 'frozenTemplate' ])
        do: [ :sel | 
            self instanceSide removeSelector: sel.
            count := count + 1 ].
        
    Transcript 
        show: '[', Time now print24, '] Unfreeze: Removed ', count asString, ' frozen templates.'; 
        cr.
]

{ #category : 'accessing' }
ConduitWebAppDemo >> conduit [
	^ conduit
]

{ #category : 'rendering' }
ConduitWebAppDemo >> renderPage: aPageName [
    | viewData pageTemplate layoutTemplate renderedPage partials |
    
    "1. Prepare the data for the templates"
    viewData := Dictionary new 
        at: 'title' put: aPageName capitalized;
        at: 'time' put: Time now print24;
        yourself.

    "2. Fetch templates (Checks Disk first, then Frozen Methods)"
    pageTemplate := self templateNamed: aPageName.
    layoutTemplate := self templateNamed: 'layout'.
    
    "3. Resolve all partials (for {{> navbar}} etc.)"
    partials := self resolvePartials.

    "4. Execute the render"
    ^ pageTemplate 
        ifNotNil: [ 
            renderedPage := pageTemplate value: viewData partials: partials.
            
            "Wrap in layout if it exists, otherwise return raw page"
            layoutTemplate 
                ifNotNil: [ 
                    viewData at: 'content' put: renderedPage.
                    layoutTemplate value: viewData partials: partials ]
                ifNil: [ renderedPage ] 
        ]
        ifNil: [ 
            TeaResponse notFound body: '<h1>404: Template not found</h1>' ]
]

{ #category : 'template-resolution' }
ConduitWebAppDemo >> resolvePartials [
    | dict |
    "If Disk is active, use its registry"
    (conduit notNil and: [ conduit registry notEmpty ]) ifTrue: [ ^ conduit registry ].
    
    "Otherwise, rebuild from Frozen methods"
    dict := Dictionary new.
    (self class selectors select: [ :s | s beginsWith: 'frozenTemplate' ]) do: [ :sel |
        | key |
        key := (sel copyFrom: 9 to: sel size) asLowercase.
        dict at: key put: (MustacheTemplate on: (self perform: sel)) ].
        
    ^ dict
]

{ #category : 'accessing' }
ConduitWebAppDemo >> rootPath [
	^ rootPath 
]

{ #category : 'accessing' }
ConduitWebAppDemo >> rootPath: aPath [
    "Only convert to a FileReference if we actually have a path"
    rootPath := aPath ifNotNil: [ aPath asFileReference ].
]

{ #category : 'initialization' }
ConduitWebAppDemo >> setupRoutes [
	"1. The Root Redirect"
    teapot GET: '/' -> [ TeaResponse redirect location: '/index'; yourself ].

    "2. The HTMX Fragment"
    teapot GET: '/clicked' -> [ 
        '<span>Content swapped successfully by <b>htmx</b> and <b>Pharo</b>!</span>'    
    ].

    "3. The Dynamic Catch-all"
    teapot GET: '/<page>' -> [ :req | self renderPage: (req at: #page) ].
]

{ #category : 'control' }
ConduitWebAppDemo >> start [
    self stop.
    
    "1. Initialize Conduit only if we have a path (Development Mode)"
    rootPath ifNotNil: [ 
        conduit := Conduit pointingAt: self rootPath pathString.
        conduit start ].

    "2. Guard: Error only if we have NO disk AND NO frozen templates"
    (rootPath isNil and: [ (self class selectors anySatisfy: [ :s | s beginsWith: 'template' ]) not ])
        ifTrue: [ self error: 'Conduit-Web Error: No rootPath set and no frozen templates found.' ].
    
    "3. Setup and Boot the Server"
    teapot := Teapot configure: { #port -> 8080. #debugMode -> true }.
    self setupRoutes.
    teapot start.
    
    "Inform the user which mode we are in"
    Transcript show: 'Conduit-Web started (Mode: ', 
        (rootPath ifNotNil: [ 'Disk/Live' ] ifNil: [ 'Image/Frozen' ]), ')'; cr.
]

{ #category : 'control' }
ConduitWebAppDemo >> stop [

	teapot ifNotNil: [ teapot stop. teapot := nil ].
	conduit ifNotNil: [ conduit stop. conduit := nil ].
	
	Teapot stopAll.
]

{ #category : 'accessing' }
ConduitWebAppDemo >> templateNamed: aName [
    | methodName |
    methodName := ('frozenTemplate' , aName capitalized) asSymbol.
    
    "1. Check Disk (Conduit)"
    (conduit notNil and: [ conduit registry includesKey: aName ])
        ifTrue: [ ^ conduit registry at: aName ].
        
    "2. Check Image (Frozen Methods)"
    (self respondsTo: methodName)
        ifTrue: [ ^ MustacheTemplate on: (self perform: methodName) ].
        
    ^ nil
]
