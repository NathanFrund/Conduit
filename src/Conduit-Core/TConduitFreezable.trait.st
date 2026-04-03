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
TConduitFreezable classSide >> freeze: aPath [
    | root |
    root := aPath asFileReference.
    
    "1. Freeze templates from templates/ subdirectory"
    (root / 'templates') exists ifTrue: [
        (root / 'templates') children select: [ :each | each isFile ] thenDo: [ :file |
            | content methodName |
            content := file contents.
            methodName := 'frozenTemplate', file base capitalized.
            self instanceSide compile: (String streamContents: [ :s |
                s nextPutAll: methodName; cr.
                s nextPutAll: '    ^ '; nextPutAll: content asString printString ])
            classified: 'frozen-templates'.
            Transcript show: '  Frozen template: ', file base; cr ] ].
    
    "2. Freeze CSS assets"
    (root / 'css') exists ifTrue: [
        (root / 'css') children select: [ :each | each isFile ] thenDo: [ :file |
            | content methodName |
            content := file contents.
            methodName := 'frozenAsset', file base capitalized, file extension capitalized.
            self instanceSide compile: (String streamContents: [ :s |
                s nextPutAll: methodName; cr.
                s nextPutAll: '    ^ '; nextPutAll: content asString printString ])
            classified: 'frozen-assets'.
            Transcript show: '  Frozen asset: css/', file base; cr ] ].
    
    "3. Freeze JS assets"
    (root / 'js') exists ifTrue: [
        (root / 'js') children select: [ :each | each isFile ] thenDo: [ :file |
            | content methodName |
            content := file contents.
            methodName := 'frozenAsset', file base capitalized, file extension capitalized.
            self instanceSide compile: (String streamContents: [ :s |
                s nextPutAll: methodName; cr.
                s nextPutAll: '    ^ '; nextPutAll: content asString printString ])
            classified: 'frozen-assets'.
            Transcript show: '  Frozen asset: js/', file base; cr ] ].
    
    Transcript show: 'Freeze complete!'; cr.
]

{ #category : 'actions' }
TConduitFreezable classSide >> freezeAsset: aFileReference category: aCategory [
    | content methodName |
    content := aFileReference contents.
    methodName := 'frozenAsset', aFileReference base capitalized, aFileReference extension capitalized.
    self instanceSide compile: (String streamContents: [ :s |
        s nextPutAll: methodName; cr.
        s nextPutAll: '    ^ '; nextPutAll: content asString printString ])
    classified: 'frozen-assets'.
    Transcript show: '  Frozen asset: ', aCategory, '/', aFileReference base; cr.
]

{ #category : 'actions' }
TConduitFreezable classSide >> freezeAssets: aPath [
    | root |
    root := aPath asFileReference.
    
    "Freeze CSS"
    (root / 'css') exists ifTrue: [
        (root / 'css') children select: [ :each | each isFile ] thenDo: [ :file |
            self freezeAsset: file category: 'css' ] ].
    
    "Freeze JS"
    (root / 'js') exists ifTrue: [
        (root / 'js') children select: [ :each | each isFile ] thenDo: [ :file |
            self freezeAsset: file category: 'js' ] ].
]

{ #category : 'actions' }
TConduitFreezable classSide >> freezeCSS: aPath [
    | root |
    root := aPath asFileReference.
    (root / 'css') exists ifTrue: [
        (root / 'css') children select: [ :each | each isFile ] thenDo: [ :file |
            self freezeAsset: file category: 'css' ] ].
    Transcript show: 'CSS assets frozen.'; cr.
]

{ #category : 'actions' }
TConduitFreezable classSide >> freezeJS: aPath [
    | root |
    root := aPath asFileReference.
    (root / 'js') exists ifTrue: [
        (root / 'js') children select: [ :each | each isFile ] thenDo: [ :file |
            self freezeAsset: file category: 'js' ] ].
    Transcript show: 'JS assets frozen.'; cr.
]

{ #category : 'actions' }
TConduitFreezable classSide >> freezeTemplates: aPath [
    | root |
    root := aPath asFileReference.
    
    (root / 'templates') exists ifFalse: [ 
        Transcript show: 'No templates directory found.'; cr.
        ^ self ].
    
    (root / 'templates') children select: [ :each | each isFile ] thenDo: [ :file |
        | content methodName |
        content := file contents.
        methodName := 'frozenTemplate', file base capitalized.
        self instanceSide compile: (String streamContents: [ :s |
            s nextPutAll: methodName; cr.
            s nextPutAll: '    ^ '; nextPutAll: content asString printString ])
        classified: 'frozen-templates'.
        Transcript show: '  Frozen template: ', file base; cr ].
]

{ #category : 'actions' }
TConduitFreezable classSide >> unfreeze [
    | count classSide |
    count := 0.
    classSide := self instanceSide.
    
    "Remove frozen templates"
    (classSide selectors select: [ :s | s beginsWith: 'frozenTemplate' ]) do: [ :sel |
        classSide removeSelector: sel.
        count := count + 1 ].
    
    "Remove frozen assets"
    (classSide selectors select: [ :s | s beginsWith: 'frozenAsset' ]) do: [ :sel |
        classSide removeSelector: sel.
        count := count + 1 ].
    
    Transcript show: '[', Time now print24, '] Unfreeze: Removed ', count asString, ' frozen methods.'; cr.
]
