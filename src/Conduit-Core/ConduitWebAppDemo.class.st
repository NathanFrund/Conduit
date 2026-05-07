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
	#traits : 'TConduitRenderer + TConduitFreezable',
	#classTraits : 'TConduitRenderer classTrait + TConduitFreezable classTrait',
	#instVars : [
		'server',
		'conduit',
		'rootPath'
	],
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'public' }
ConduitWebAppDemo class >> startOn: aPath [

	| instance |
	instance := self new.
	aPath ifNotNil: [
			instance rootPath: aPath asFileReference.
			instance start ].
	^ instance
]

{ #category : 'accessing' }
ConduitWebAppDemo >> conduit [
	^ conduit
]

{ #category : 'public' }
ConduitWebAppDemo >> handleRequest: request [
    | path |
    path := request uri pathPrintString.
    path = '/' ifTrue: [ ^ ZnResponse redirect: '/templates/index' ].
    path = '/clicked' ifTrue: [
        ^ ZnResponse ok: (ZnEntity html: '<span>Content swapped successfully by <b>htmx</b> and <b>Pharo</b>!!</span>') ].
    ^ self respondWithPage: (path copyWithoutFirst: $/).
]

{ #category : 'rendering' }
ConduitWebAppDemo >> renderPage: aPageName [
    "Render a full page using the layout template ('layout') if present,
     or just the raw page content."
    | viewData pageTemplate layoutTemplate renderedPage partials |
    viewData := Dictionary new
        at: 'title' put: aPageName capitalized;
        at: 'time' put: Time now print24;
        yourself.

    pageTemplate := self templateNamed: aPageName.
    layoutTemplate := self templateNamed: 'layout'.
    partials := self resolvePartials.

    ^ pageTemplate
        ifNotNil: [
            renderedPage := pageTemplate value: viewData partials: partials.
            layoutTemplate
                ifNotNil: [
                    viewData at: 'content' put: renderedPage.
                    layoutTemplate value: viewData partials: partials ]
                ifNil: [ renderedPage ] ]
        ifNil: [ '<h1>404: Template not found</h1>' ].
]

{ #category : 'request handling' }
ConduitWebAppDemo >> respondWithPage: aPageName [
    | html |
    html := self renderPage: aPageName.
    ^ ZnResponse ok: (ZnEntity html: html)
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

{ #category : 'control' }
ConduitWebAppDemo >> start [
    self stop.
    rootPath ifNotNil: [
        conduit := Conduit pointingAt: rootPath pathString.
        conduit start ].
    server := ZnServer on: 8080.
    server delegate: self.
    server start.
    Transcript show: 'Conduit-Web started (Mode: ',
        (rootPath ifNotNil: [ 'Disk/Live' ] ifNil: [ 'Image/Frozen' ]), ')'; cr.
]

{ #category : 'control' }
ConduitWebAppDemo >> stop [
    server ifNotNil: [ server stop. server := nil ].
    conduit ifNotNil: [ conduit stop. conduit := nil ].
]
