"
I am a filesystem bridge and hot-reloading registry for web assets. 

I act as the ""Disk-Side"" counterpart to the ConduitWebApp, responsible for watching a local directory and keeping an in-memory map of Mustache templates.

Responsibilities:
- File System Monitoring: I track changes in a specified root directory (usually 'shared').
- Template Registry: I maintain a Dictionary (#registry) where keys are filenames and values are MustacheTemplate instances.
- Hot-Reloading: When a file is saved on disk, I automatically re-parse the content so the running web app reflects changes immediately.

Internal Representation and Key Implementation Points:
- #rootPath: A FileReference pointing to the directory containing .mustache or .html files.
- #registry: A Dictionary mapping template names (Symbols) to compiled MustacheTemplate objects.
- #watcher: (Optional) The TKTWatcher or process responsible for monitoring file events.

Public API:
- Conduit on: aPathString : Primary constructor to initialize with a specific folder.
- #templateNamed: aName : Returns a compiled template from the registry, or nil if not found.

Example:
    | c |
    c := Conduit on: '/var/shared'.
    c registry keys. ""Returns all detected template names""
"
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
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
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

{ #category : 'control' }
Conduit >> start [
	self stop. "Ensure no duplicate processes"
	watcherProcess := [
		[ true ] whileTrue: [ 
			self syncFiles.
			(Delay forSeconds: 1) wait.
		]	
	] forkAt: Processor userBackgroundPriority named: 'ConduitWatchr'. 
]

{ #category : 'control' }
Conduit >> stop [
	watcherProcess ifNotNil: [ 
		watcherProcess terminate.
		watcherProcess := nil
	].
	registry removeAll.
	lastCheck := DateAndTime unixEpoch.
]

{ #category : 'updating' }
Conduit >> syncFiles [
	| currentFiles diskNames |
	"Find all files that match our registered extensions"
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
