Trait {
	#name : 'TConduitFreezable',
	#category : 'Conduit-Core',
	#package : 'Conduit-Core'
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
