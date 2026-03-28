"
I am a trait that provides ""static fallback"" capabilities for web templates.

My primary purpose is to allow a web application to function even when its external assets (like .mustache files on disk) are missing. I do this by reflecting on my user's methods to find ""frozen"" versions of those templates.

## 1. The ""Freezing"" Concept
When an application is ""frozen"" for distribution (e.g., creating a standalone .image file), external file dependencies can be brittle. This trait allows developers to store template strings directly in methods, ensuring the UI remains intact without a local shared/ folder.

## 2. Key Logic
Naming Convention: I look for any method beginning with the prefix frozenTemplate.

Key Generation: I extract the template name by stripping the prefix and converting the remainder to lowercase. (e.g., frozenTemplateIndex becomes the key 'index').

Registry Building: I am typically used by #resolvePartials to populate a template dictionary when the disk-based conduit registry is unavailable.

## 3. Requirement
Classes using me should implement or provide access to a conduit object or a registry to determine when to trigger the ""frozen"" fallback.

## 4. Example Method
Smalltalk
frozenTemplateIndex
    ^ '<html><body><h1>Hello from the Image!</h1></body></html>'
"
Trait {
	#name : 'TConduitFreezable',
	#category : 'Conduit-Core-Base',
	#package : 'Conduit-Core',
	#tag : 'Base'
}

{ #category : 'actions' }
TConduitFreezable >> freeze: aPath [
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

    Transcript show: 'Freeze complete: Assets frozen in Instance Side.'; cr.
]

{ #category : 'actions' }
TConduitFreezable >> unfreeze [
	| count |
	count := 0. 
	(self instanceSide selectors select: [ :s | s beginsWith: 'frozenTemplate' ])
		do: [ :sel |
			self instanceSide removeSelector: sel. 
			count := count + 1 ]. 

	Transcript 
		show: '[', Time now print24, '] Unfreeze: Removed ', count asString, ' frozen templates.'; 
		cr.
]
