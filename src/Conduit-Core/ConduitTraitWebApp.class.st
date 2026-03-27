Class {
	#name : 'ConduitTraitWebApp',
	#superclass : 'Object',
	#traits : 'TConduitRenderer',
	#classTraits : 'TConduitFreezable classTrait',
	#instVars : [
		'conduit',
		'rootPath',
		'server'
	],
	#category : 'Conduit-Core',
	#package : 'Conduit-Core'
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
