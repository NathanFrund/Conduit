Class {
	#name : 'Conduit',
	#superclass : 'Object',
	#instVars : [
		'watcherProcess',
		'registry',
		'rootFolder',
		'processors',
		'lastCheck'
	],
	#category : 'Conduit-Core',
	#package : 'Conduit-Core'
}

{ #category : 'accessing' }
Conduit class >> pointingAt: aPathString [
	^ self new
		rootFolder: aPathString asFileReference;
		yourself 
]

{ #category : 'initialization' }
Conduit >> initialize [ 
	super initialize.
	registry := Dictionary new.
	processors := Dictionary new.
	lastCheck := DateAndTime unixEpoch.
	
	"Default: Users can override these laster"
	processors at: 'mustache' put: [ :c | c asMustacheTemplate ].
	processors at: 'html' put: [ :c | c ].
]

{ #category : 'accessing' }
Conduit >> processors [
	^ processors 
]

{ #category : 'accessing' }
Conduit >> registry [ 
	^ registry 
]

{ #category : 'accessing' }
Conduit >> rootFolder: aFileReference [
	rootFolder := aFileReference asFileReference.
]

{ #category : 'accessing' }
Conduit >> start [
	self stop. "Ensure no duplicate processes"
	watcherProcess := [
		[ true ] whileTrue: [ 
			self syncFiles.
			(Delay forSeconds: 1) wait.
		]	
	] forkAt: Processor userBackgroundPriority named: 'ConduitWatchr'. 
]

{ #category : 'accessing' }
Conduit >> stop [
	watcherProcess ifNotNil: [ 
		watcherProcess terminate.
		watcherProcess := nil
	].
]

{ #category : 'as yet unclassified' }
Conduit >> syncFiles [
	| currentFiles diskNames |
	"Find all files that match our gegistered extenssions"
	currentFiles := rootFolder allFiles select: [ :f | processors includesKey: f extension ].
	diskNames := currentFiles collect: [ :f | f basenameWithoutExtension ].
	
	"Add/Update files"
	currentFiles do: [ :file |
		(file modificationTime > lastCheck ) ifTrue: [ 
			| processor |
			processor := processors at: file extension.
			registry at: file basenameWithoutExtension put: (processor value: file contents).
		].
	].

	"Remove files that were deleted from disk"
	(registry keys copy) do: [ :key |
		(diskNames includes: key) ifFalse: [ registry removeKey: key ] ].
	
	lastCheck := DateAndTime now.
	

]
