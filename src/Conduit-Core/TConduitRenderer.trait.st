Trait {
	#name : 'TConduitRenderer',
	#category : 'Conduit-Core',
	#package : 'Conduit-Core'
}

{ #category : 'accessing' }
TConduitRenderer >> conduit [ 
	^ self subclassResponsibility 
]

{ #category : 'rendering' }
TConduitRenderer >> renderPage: aPageName [
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
		ifNil: [ '<h1>404: Template not found</h1>' ]
]

{ #category : 'template-resolution' }
TConduitRenderer >> resolvePartials [
	| dict |
	"If Disk is active, use its registry" 
	(self conduit notNil and: [ self conduit registry notEmpty ]) 
		ifTrue: [ ^ self conduit registry ]. 

	"Otherwise, rebuild from Frozen methods" 
	dict := Dictionary new. 
	(self class selectors select: [ :s | s beginsWith: 'frozenTemplate' ]) do: [ :sel | 
		| key |
		key := (sel copyFrom: 15 to: sel size) asLowercase. "Updated offset for 'frozenTemplate'" 
		dict at: key put: (MustacheTemplate on: (self perform: sel)) ]. 
	^ dict 
]

{ #category : 'accessing' }
TConduitRenderer >> templateNamed: aName [
    | methodName |
    methodName := ('frozenTemplate' , aName capitalized) asSymbol.

    "1. Check Disk (Via the conduit method, not a variable)"
    (self conduit notNil and: [ self conduit registry includesKey: aName ])
        ifTrue: [ ^ self conduit registry at: aName ].

    "2. Check Image (Frozen Methods)"
    (self respondsTo: methodName)
        ifTrue: [ ^ MustacheTemplate on: (self perform: methodName) ].

    ^ nil
]
